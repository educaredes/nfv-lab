# RDSV/SDNV P4  - Plataforma de orquestación de servicios basados en NFV

- [RDSV/SDNV P4  - Plataforma de orquestación de servicios basados en NFV](#rdsvsdnv-p4----plataforma-de-orquestación-de-servicios-basados-en-nfv)
  - [Resumen](#resumen)
  - [Escenario](#escenario)
  - [Entrega de resultados](#entrega-de-resultados)
  - [Desarrollo de la práctica](#desarrollo-de-la-práctica)
    - [1. Instalación en dos PCs](#1-instalación-en-dos-pcs)
    - [2. Arranque de escenarios VNX](#2-arranque-de-escenarios-vnx)
    - [3. Definición del cluster k8s en OSM](#3-definición-del-cluster-k8s-en-osm)
    - [4. Familiarización con GUI de OSM](#4-familiarización-con-gui-de-osm)
    - [5. Repositorios de helm charts y docker](#5-repositorios-de-helm-charts-y-docker)
    - [6. (P) Relación entre helm y docker](#6-p-relación-entre-helm-y-docker)
    - [7. Instalación de descriptores en OSM](#7-instalación-de-descriptores-en-osm)
    - [8. (P) Análisis de descriptores](#8-p-análisis-de-descriptores)
    - [9. Creación de instancias del servicio](#9-creación-de-instancias-del-servicio)
    - [10. Comprobación de los pods arrancados](#10-comprobación-de-los-pods-arrancados)
    - [11. (P) Acceso a los pods ya arrancados](#11-p-acceso-a-los-pods-ya-arrancados)
    - [12. (P) Scripts de configuración del servicio](#12-p-scripts-de-configuración-del-servicio)
    - [13. (P) Configuración del servicio](#13-p-configuración-del-servicio)
    - [14. (P) Servicio desde la red de acceso](#14-p-servicio-desde-la-red-de-acceso)
    - [15. (P) Análisis de tráfico en AccessNet1](#15-p-análisis-de-tráfico-en-accessnet1)
    - [16. (P) Análisis de tráfico en ExtNet1](#16-p-análisis-de-tráfico-en-extnet1)
    - [17. (P) Servicio para la segunda red residencial](#17-p-servicio-para-la-segunda-red-residencial)

## Resumen
En esta práctica, se va a utilizar la plataforma de código abierto [Open Source
MANO (OSM)](https://osm.etsi.org) para profundizar en la orquestación de
funciones de red virtualizadas. El escenario que se va a utilizar está inspirado
en la reconversión de las centrales locales a centros de datos que permiten,
entre otras cosas, reemplazar servicios de red ofrecidos mediante hardware
específico y propietario por servicios de red definidos por software sobre
hardware de propósito general. Las funciones de red que se despliegan en estas
centrales se gestionan mediante una plataforma de orquestación como OSM o XOS. 

El servicio de red objeto de estudio es el servicio residencial de acceso a
Internet. La  Fig. 1 ilustra las funciones que tradicionalmente realiza el
“router residencial” (Customer Premises Equipment – CPE) desplegado en casa del
usuario, como switch Ethernet / punto de acceso WiFi, servidor DHCP, traducción
de direcciones NAT y reenvío de datagramas IP. El objetivo de la práctica es
estudiar como esas funciones pasarán a realizarse en la central local. 

![CPE tradicional](img/nfv-lab-figura1.drawio.png)

*Fig. 1. CPE tradicional*

Como se observa en la Fig. 2, el router residencial se sustituye por un equipo
que llamaremos “Bridged Residential Gateway (BRG)” que realiza la conmutación de
nivel 2 del tráfico de los usuarios entre la red residencial y la central local.
El resto de las funciones (DHCP, NAT y router para reenvío IP) se realizan en la
central local aplicando técnicas de virtualización de funciones de red (NFV),
creando un servicio de CPE virtual (vCPE) gestionado mediante la plataforma de
orquestación. 

![CPE virtualizado](img/nfv-lab-figura2.drawio.png)

*Fig. 2. CPE virtualizado*

## Escenario

La Fig. 3 muestra una visión global del escenario que se va a emular, con dos
sistemas finales h11 y h12 en casa del usuario, conectados al brg1 que, a través
de la red de acceso AccessNet se conecta a su vez a la central local, donde el
servicio de red residencial "RENES" (REsidential NEtwork Service) se va a
ofrecer a través de dos VNF implementadas mediante Kubernetes (KNF):

- Una KNF:access, que se conecta a la red de acceso y permitiría clasificar el
  tráfico e implementar QoS en el acceso del usuario a la red.
- Una KNF:vcpe, que integrará las funciones de servidor DHCP, NAT y reenvío de
  IP. 

El entorno utilizado para gestionar los servicios de red es OSM.

![Visión global del escenario](img/nfv-lab-figura3.drawio.png)

*Fig. 3. Visión global del escenario*

El escenario explicado se va a implementar para la práctica en dos máquinas
Linux en VirtualBox, conectadas a la red `192.168.56.0/24` junto con el PC
anfitrión (`192.168.56.1`): 

- **RDSV-K8S** (`192.168.56.11`). Permite emular las distintas redes y hosts del
  escenario, y el cluster de Kubernetes (K8s) de la central local. Tiene
  instaladas las herramientas:
   - el paquete _microk8s_ para proporcionar la funcionalidad de k8s
   - la herramienta _VNX_, que se usará para emular los equipos de la red
     residencial, el router isp1 y el servidor s1
   - _Open vSwitch (ovs)_, que permitirá emular la red de acceso AccessNet1, la
     red externa ExtNet1 que da salida al router isp1, y que además se utiliza
     tanto en la emulación del bgr1 como en las KNFs
- **RDSV-OSM** (`192.168.56.12`). Instalación del entorno _OSM_, al que se
  accede gráficamente con un navegador, o mediante terminal con el comando `osm`.

Esas máquinas tendrán conectividad entre ellas y con el host a través de la red
192.168.56.0/24.

El detalle del escenario se puede ver en la Fig 4. 

![Visión detallada del escenario](img/nfv-lab-figura4.drawio.png)

*Fig. 4. Visión detallada del escenario*

Como se refleja en la figura, se utilizará la tecnología _VXLAN_ para enviar
encapsuladas en datagramas UDP las tramas de nivel 2 que viajan entre brg1,
KNF:access y KNF:cpe. Para permitir esta comunicación, tanto el brg1 como
KNF:access tendrán interfaces en AccessNet1, configuradas con direcciones IP del
prefijo 10.255.0.0/24. La asignación de direcciones IP a KNF:access y KNF:cpe en
la red que las interconecta está gestionada por OSM y k8s, de manera que se
asignan dinámicamente al instanciar las KNFs.

## Entrega de resultados

En los apartados siguientes encontrará algunos marcados con (P). Deberá 
responder a esos apartados en un documento memoria-p4.pdf.

Suba a través del Moodle un único fichero zip que incluya el fichero pdf y las
capturas que se solicitan.

## Desarrollo de la práctica
### 1. Instalación en dos PCs

Cada alumno, desde cuentas diferentes, accederá a un PC,  _pc-k8s_ 
para el clúster de K8S, y _pc-osm_ para OSM. 

En _pc-k8s_ ejecute:

```
# En pc-k8s, instala y arranca RDSV-K8S y la conecta con OSM en pc-osm
/lab/rdsv/get-osmlab2 RDSV-K8S pc-osm
```
>Ejemplo, con pc-osm=l060 y pc-k8s=l059
>
>```
>/lab/rdsv/get-osmlab2 RDSV-K8S l060
>```
>

En _pc-osm_ ejecute:

```
# En pc-osm, instala y arranca RDSV-OSM y la conecta con K8S en pc-k8s
/lab/rdsv/get-osmlab2 RDSV-OSM pc-k8s
```


>Ejemplo, con pc-osm=l060 y pc-k8s=l059
>
>```
>/lab/rdsv/get-osmlab2 RDSV-OSM l059
>```
>

Desde cualquiera de los dos PCs compruebe la conectividad a ambas máquinas:

```
ping -c 5 192.168.56.11  # K8S
ping -c 5 192.168.56.12  # OSM
```

Si hay conectividad, configure la MTU de la interfaz eth1 en ambas máquinas:

```
ssh upm@192.168.56.11 "sudo ip link set dev eth1 mtu 1400"
```

```
ssh upm@192.168.56.12 "sudo ip link set dev eth1 mtu 1400"
```

Además descargue en la carpeta shared en ambos PCs, el repositorio de la 
práctica:

```
cd ~/shared
git clone https://github.com/educaredes/nfv-lab.git
cd nfv-lab
```

>Nota: si ya lo ha descargado antes puede actualizarlo con:
>```
>cd ~/shared/nfv-lab
>git pull
>```

Para los apartados siguientes, considere que _pc-k8s_, en el que ha arrancado
_RDSV-K8S_, es el _PC anfitrión_ (estará menos cargado).

>#### 1.alt. Instalación en un único PC
>
>Alternativamente, para tener todo el entorno en una única máquina, ejecute en un
>PC del laboratorio:
>
>```
>/lab/rdsv/rdsv-get-osmlab
>```
>
>Este comando:
>- instala la ova que contiene las dos máquinas virtuales en VirtualBox,
>- crea la red de interconexión entre ellas, si no está ya creada,
>- crea el directorio `$HOME/shared` en la cuenta del usuario del laboratorio y
>la añade como directorio compartido en las dos máquinas virtuales, en
>`/home/upm/shared`. El objetivo es que esa carpeta compartida sea accesible 
>tanto en el PC anfitrión como en las máquinas _RDSV-OSM_ y _RDSV-K8S_. 
>
>A continuación descargue en ese directorio compartido el repositorio de la
>práctica: 
>
>```
>cd ~/shared
>git clone https://github.com/educaredes/nfv-lab.git
>cd nfv-lab
>```
>
>Y arranque por línea de comando las máquinas:
>
>```
>vboxmanage startvm RDSV-OSM --type headless # arrancar sin interfaz gráfica
>vboxmanage startvm RDSV-K8S
>``` 
>
>> **Nota:**
>> El entorno OSM puede tardar varios minutos en terminar de arrancar.

### 2. Arranque de escenarios VNX 

Acceda a _RDSV-K8S_ y compruebe que están creados los switches `AccessNet1` y
`ExtNet1` tecleando en un terminal:

```
sudo ovs-vsctl show
```

Compruebe también mediante un ping la conectividad con _RDSV-OSM_ y con el PC 
anfitrión.

```
ping -c 5 192.168.56.12
ping -c 5 192.168.56.1
```

A continuación arranque el escenario de la red residencial:

```
cd /home/upm/shared/nfv-lab
sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -t
```

El escenario contiene dos redes residenciales, nos centraremos inicialmente en
la primera de ellas (sistemas finales h11 y h12). Compruebe en los terminales
de los hosts h11 y h12 que no tienen asignada dirección IP en la interfaz 
`eth1` mediante:

```
ifconfig eth1
```

> **Nota:**
> Los hosts tienen configurada la red de gestión VNX en la interfaz `eth0`.

Compruebe también que el cliente DHCP no les permite obtener dirección IP y que
no tienen acceso a Internet:

```
dhclient eth1
ifconfig
ping 8.8.8.8
```

Arranque también el escenario "server"

```
sudo vnx -f vnx/nfv3_server_lxc_ubuntu64.xml -t
```

Finalmente, para permitir el acceso a aplicaciones con entorno gráfico desde las
máquinas arrancadas con VNX ejecute:

```
xhost +
```

> **Nota:**
> Mostrará como salida:
>
>```
>access control disabled, clients can connect from any host
>```

### 3. Definición del cluster k8s en OSM

Ahora desde el _PC anfitrión_ use un terminal para acceder a _RDSV-OSM_:

```
# Ejecutar desde el PC anfitrión
ssh -l upm 192.168.56.12  # password: xxxx
```

A continuación, compruebe que OSM tiene configurado un cluster de k8s mediante 
el comando:

```
osm k8scluster-list
```

El campo *id* del cluster es un identificador que se puede usar para gestionar
 el clúster. Para ver más información, utilice:

```
KID=<id obtenido de k8scluster-list>   # todo seguido, sin espacios y sin < >
osm k8scluster-show $KID
```

En el resultado del show, busque la información sobre el `namespace` que va
a utilizar OSM en el clúster para desplegar los pods de los servicios de red. 
Puede utilizar:

```
osm k8scluster-show --literal $KID | grep -A1 projects
```

Defina una variable para guardar ese valor, que se utilizará en los scripts 
de la práctica.

```
export OSMNS=<namespace> # todo seguido, sin espacios y sin < >
```
> **Ejemplo:**
> >
>```
>export OSMNS=7b2950d8-f92b-4041-9a55-8d1837ad7b0a
>```

Desde el terminal en _RDSV-OSM_, comprobemos que el cliente de k8s `kubectl`
está configurado para acceder al clúster. Liste los namespaces del clúster,
desde el terminal:

```
# Desde terminal en RDSV-OSM
kubectl get namespaces
```

Deberá ver que entre los namespaces se encuentra el valor que ha obtenido
mediante `osm`.

### 4. Familiarización con GUI de OSM

Desde el _PC anfitrión_, acceda a la interfaz gráfica de _OSM_:

```
# Acceso desde el PC anfitrión, user/pass: admin/admin
firefox 192.168.56.12 &
```

Familiarícese con las distintas opciones del menú, especialmente:
- _Packages_: gestión de las plantillas de servicios de red (NS Packages)
y VNFs. 
- _Instances_: gestión de la instancias de los servicios desplegados
- _K8s_: gestión del registro de clústeres y repositorios k8s

### 5. Repositorios de helm charts y docker

A través de la GUI registraremos el repositorio de helm charts que 
utilizaremos en la práctica, alojado en Github Pages.

Acceda a la opción de menú _K8s Repos_, haga clic sobre el botón
 _Add K8s Repository_ y rellene los campos con los valores:
- id: `helmchartrepo`
- type: "Helm Chart" 
- URL: `https://educaredes.github.io/nfv-lab` (NO DEBE TERMINAR EN "/")
- description: _una descripción textual del repositorio_

![new-k8s-repository-details](img/new-k8s-repository.png)

En la carpeta compartida `$HOME/shared/nfv-lab/helm` puede encontrar las
definiciones de los helm charts `accesschart` y `cpechart`, mientras que en
`$HOME/shared/nfv-lab/img` está la definición del contenedor docker único que se
va a utilizar, `educaredes/vnf-img`. Este contenedor está alojado en DockerHub,
compruébelo accediendo a [este enlace](https://hub.docker.com/u/educaredes).

### 6. (P) Relación entre helm y docker

Busque en la carpeta `helm` en qué ficheros se hace referencia al contenedor
docker. Anote el resultado para incluirlo como parte de la entrega. Puede 
utilizar:

```
grep -R "educaredes/vnf-img"
```

### 7. Instalación de descriptores en OSM

Desde el _PC anfitrión_, acceda gráficamente al directorio 
`$HOME/shared/nfv-lab/pck`. Realice el proceso de instalación de los 
descriptores de las KNFs y del servicio de red (onboarding):
- Acceda al menu de OSM Packages->VNF packages y arrastre los ficheros 
`accessknf_vnfd.tar.gz` y `cpeknf_vnfd.tar.gz`   
- Acceda al menu de OSM Packages->NS packages y arrastre el fichero 
`renes_ns.tar.gz`

### 8. (P) Análisis de descriptores

Acceda a la descripción de las VNFs/KNFs y del servicio. Para entregar como 
resultado de la práctica:
1.	En la descripción de las VNFs, identifique y copie la información referente
al helm chart que se utiliza para desplegar el pod correspondiente en el clúster
de Kubernetes.
2.	En la descripción del servicio, identifique y copie la información 
referente a las dos VNFs.

### 9. Creación de instancias del servicio

Desde el terminal en _RDSV-OSM_, lanzamos los siguientes comandos:

```
export NSID1=$(osm ns-create --ns_name renes1 --nsd_name renes --vim_account dummy_vim)
echo $NSID1
```

Mediante el comando `watch` visualizaremos el estado de la instancia del 
servicio, que hemos denominado `renes1`. 

```
watch osm ns-list
```

Espere a que alcance el estado _READY_ y salga con `Ctrl+C`.

Si se produce algún error, puede borrar la instancia del servicio con el 
comando:

```
osm ns-delete $NSID1
```

Acceda a la GUI de OSM, opción NS Instances, para ver cómo también es posible
gestionar el servicio gráficamente.

### 10. Comprobación de los pods arrancados

Desde el terminal en _RDSV-OSM_, usaremos kubectl para obtener los pods que 
han arrancado en _RDSV-K8S_:

```
kubectl -n $OSMNS get pods
```

A continuación, defina dos variables:

```
ACCPOD=<nombre del pod de la KNF:access>
CPEPOD=<nombre del pod de la KNF:cpe>
```

### 11. (P) Acceso a los pods ya arrancados

Haga una captura del texto o captura de pantalla del resultado de los 
siguientes comandos y explique dicho resultado. ¿Qué red están utilizando 
los pods para esa comunicación?

```
kubectl -n $OSMNS exec -it $ACCPOD -- ifconfig eth0
# anote la dirección IP

kubectl -n $OSMNS exec -it $CPEPOD -- /bin/bash
# Y a continuación haga un ping a la dirección IP anotada
# salga con exit
```

### 12. (P) Scripts de configuración del servicio

Desde el _PC anfitrión_ acceda (mediante vi, nano, gedit, ...) al contenido 
del fichero `osm_renes1.sh` utilizado para configurar la instancia renes1 del
servicio. Compare los valores utilizados con los de la figura detallada del 
escenario. Indique cuál es la dirección IP "pública" (en realidad es de un 
rango privado), que deberá usar la función NAT del CPE para dar salida al 
tráfico de la red residencial hacia Internet. 

> **Parte opcional, para hacer tras la sesión del laboratorio:** 
> Analice y describa para qué se utilizan los scripts `osm_renes_start.sh` y 
`renes_start.sh`.

### 13. (P) Configuración del servicio

Desde _RDSV-OSM_, configure el servicio renes1 mediante `osm_renes1.sh`:

```
./osm_renes1.sh
```

Analice a continuación el detalle del escenario en la Fig. 4 e indique 
qué comando(s) puede utilizar **desde _RDSV-OSM_** para comprobar si hay 
conectividad entre el servicio desplegado y el dispositivo `brg1` de la 
red residencial. Verifique que haya conectividad. 

### 14. (P) Servicio desde la red de acceso

Compruebe la configuración de red de h11 y h12 y, si no han obtenido dirección 
IP, fuerce el acceso al servidor DHCP mediante el comando:

```
dhclient eth1
```

Indique qué direcciones IP obtienen h11 y h12 en la red residencial “privada”, 
así como la dirección IP del router.

Relacione el resultado con los ficheros de configuración del contenedor docker 
`educaredes/vnf-img` incluidos en el directorio 
`$HOME/shared/nfv-lab/img/vnf-img`.

### 15. (P) Análisis de tráfico en AccessNet1

Desde _RDSV-K8S_, arranque wireshark y póngalo a capturar el tráfico en
`AccessNet1`, usando:

```
wireshark -ki brg1-e2 &
```

Desde h11 realice un ping de 5 paquetes a la dirección IP de su router, 
comprobando que funciona correctamente.

```
ping -c 5 <dir_IP_router>
```

Detenga wireshark, y guarde la captura con nombre “access1.pcapng”. Analice 
el tráfico capturado, justificando las direcciones IP que aparecen en los 
paquetes capturados.

### 16. (P) Análisis de tráfico en ExtNet1

Arranque wireshark y póngalo a capturar el tráfico en ExtNet, por ejemplo 
haciendo:

```
wireshark -ki isp1-e1 &
```

Desde h11 realice un ping de 5 paquetes a la dirección IP de s1 (10.100.3.2), 
comprobando que funciona correctamente.

```
ping -c 5 10.100.3.2
```

Detenga wireshark, y guarde la captura con nombre “ext1.pcapng”. Analice el 
tráfico capturado, justificando las direcciones IP que aparecen en 
los paquetes capturados.

Desde la consola de h11, compruebe que tiene acceso a Internet. Además de usar 
ping, puede arrancar un navegador.

```
ping -c 5 8.8.8.8
firefox www.dit.upm.es &
```

### 17. (P) Servicio para la segunda red residencial

Indique y realice los pasos necesarios para dar acceso a Internet a la 
segunda red residencial (h21, h22). Para la configuración del servicio, 
tome como punto de partida `osm_renes1.sh` y cree un nuevo script
`osm_renes2.sh`. 

Compruebe que los pasos dados funcionan correctamente:
- compruebe que h21 y h22 obtienen acceso a Internet
- compruebe que a su vez sigue funcionando la primera red residencial (h11, h12)
- indique qué direcciones IP han obtenido h21 y h22

Incluya además el contenido de `osm_renes2.sh` en la memoria de respuestas.








