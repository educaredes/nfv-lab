# RDSV/SDNV Recomendaciones sobre el trabajo final

- [RDSV/SDNV Recomendaciones sobre el trabajo final](#rdsvsdnv-recomendaciones-sobre-el-trabajo-final)
  - [1. Instalación y arranque de las máquina virtuales en el laboratorio](#1-instalación-y-arranque-de-las-máquina-virtuales-en-el-laboratorio)
  - [2. Repositorios propios](#2-repositorios-propios)
    - [Carpetas](#carpetas)
    - [Repositorio docker](#repositorio-docker)
    - [Creación del repositorio helm](#creación-del-repositorio-helm)
  - [3. Túneles VXLAN en KNF:access](#3-túneles-vxlan-en-knfaccess)
  - [4. Modificación de la imagen de los contenedores de los escenarios VNX](#4-modificación-de-la-imagen-de-los-contenedores-de-los-escenarios-vnx)
  - [5. Partes opcionales](#5-partes-opcionales)
    - [Repositorio Docker privado](#repositorio-docker-privado)
  - [Otras recomendaciones](#otras-recomendaciones)


## 1. Instalación y arranque de las máquina virtuales en el laboratorio

Siga las instrucciones del la [práctica 4](RDSV-p4.md) para instalar y arrancar
las máquinas virtuales en el laboratorio. Por prestaciones, se recomienda la
[instalación en dos PCs](RDSV-p4.md#1-instalación-en-dos-pcs).

## 2. Repositorios propios

### Carpetas

Se recomienda trabajar en la carpeta compartida `shared`.  Deberá crear dentro
de ella una carpeta `rdsv-final`, y en ella copiar las siguientes carpetas de la
práctica 4:
- `helm`
- `img`
- `pck`
- `vnx`
  
Además, copie los scripts:
- `renes_start.sh`
- `osm_renes_start.sh`
- `osm_renes1.sh`, `osm_renes2.sh`

### Repositorio docker

Cree una cuenta gratuita en Docker Hub https://hub.docker.com para subir su
contenedor Docker. A continuación, acceda a la carpeta con las definiciones de
la imagen docker y haga login para poder subir la imagen al repositorio:

```
cd img/vnf-img
docker login -u <cuenta>  # pedirá password la primera vez
```

A continuación, para evitar que la instalación del paquete `tzdata` solicite
interactivamente información sobre la zona horaria, añada al fichero
`Dockerfile`, tras la primera línea:

```
# variables to automatically install tzdata 
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Madrid
```

Después, añadir un fichero README.txt que incluya los nombres de los integrantes
del grupo en el contenedor, añadiendo una sentencia COPY al Dockerfile

Además, se puede ya modificar el Dockerfile para que incluya los paquetes de ubuntu 
"ryu-bin" y "arpwatch". Deberá también añadir el fichero
`qos_simple_switch_13.py` con la modificación que se propone en la
[práctica de QoS](http://osrg.github.io/ryu-book/en/html/rest_qos.html)

Una vez hecho esto, puede crear el contenedor:

```
docker build -t <cuenta>/vnf-img .
```

Y subirlo a Docker Hub

```
docker push <cuenta>/vnf-img
cd ../..
```

### Creación del repositorio helm

Cree a través de github.com un repositorio git, vacío inicialmente, para
crear su repositorio helm. Llámelo `repo-rdsv`. Descárguelo en la carpeta
 `rdsv-final` y mueva la carpeta `helm` junto con todo su contenido 
a `repo-rdsv`:

```
cd ~/shared/rdsv-final
mv helm repo-rdsv/
```

Aplique los siguientes cambios:

```
cd ~/shared/repo-rdsv/helm
# cambiar en los ficheros values.yaml de cada helm chart el valor de
image:
  repository: educaredes/vnf-img --> <cuenta>/vnf-img

# y actualizar 
cd ..
helm package helm/accesschart
helm package helm/cpechart
helm repo index --url https://cuenta-git.github.io/repo-rdsv/ .

# comprobar que se ha actualizado el fichero index.yaml

# y finalmente subir todo a github

git add -A
git commit -m "Crea helm charts"
git push 
```

Activar Pages en el repo de github:
- Ir a settings y en el menú lateral escoger Pages
- En branch, elegir la rama "main"
- Acceder a https://cuenta-git.github.io/repo-rdsv/index.yaml y comprobar
  el contenido

Finalmente, arrancar desde OSM una instancia del servicio renes y mediante
kubectl acceder a los contenedores para comprobar que incluyen el software
y los ficheros instalados.

## 3. Túneles VXLAN en KNF:access

La gestión de la calidad de servicio que hay que implementar en la KNF:access no
funciona adecuadamente cuando se aplica sobre interfaces de túneles VXLAN
creados desde un Open vSwitch, tal como se realiza en la P4. Por ello, es
necesario crear los túneles desde Linux con el comando ‘ip link’.

Para realizar este cambio en KNF:access, debe sustituir las siguientes dos
líneas del fichero renes_start.sh: 

```
$ACC_EXEC ovs-vsctl add-port brint vxlanacc -- set interface vxlanacc type=vxlan options:remote_ip=$HOMETUNIP
$ACC_EXEC ovs-vsctl add-port brint vxlanint -- set interface vxlanint type=vxlan options:remote_ip=$IPCPE options:key=inet options:dst_port=8742
```

Por estas otras líneas:

```
$ACC_EXEC ip link add vxlanacc type vxlan id 0 remote $HOMETUNIP dstport 4789 dev net1
# En la siguiente línea se ha corregido el dispositivo, que debe ser eth0
$ACC_EXEC ip link add vxlanint type vxlan id 1 remote $IPCPE dstport 8742 dev eth0
$ACC_EXEC ovs-vsctl add-port brint vxlanacc
$ACC_EXEC ovs-vsctl add-port brint vxlanint
$ACC_EXEC ifconfig vxlanacc up
$ACC_EXEC ifconfig vxlanint up
```

También es necesario cambiar el valor de "options:key" para KNF:cpe, en el
comando que crea el túnel, sustituyendo:

```
$CPE_EXEC ovs-vsctl add-port brint vxlanint -- set interface vxlanint type=vxlan options:remote_ip=$IPACCESS options:key=inet options:dst_port=8742
```

por:

```
$CPE_EXEC ovs-vsctl add-port brint vxlanint -- set interface vxlanint type=vxlan options:remote_ip=$IPACCESS options:key=1 options:dst_port=8742
```

Para ver la configuración completa de un túnel VXLAN en Linux, puede utilizar 
(ejemplo para interfaz vxlanacc):

```
ip -d link show vxlanacc
```

En caso de que realice la parte opcional de controlar también la calidad de
servicio en brg1, deberá sustituir también el comando que crea el túnel VXLAN
desde brg1.

## 4. Modificación de la imagen de los contenedores de los escenarios VNX

Para instalar nuevos paquetes en la imagen
`vnx_rootfs_lxc_ubuntu64-20.04-v025-vnxlab` utilizada por los contenedores
arrancados mediante VNX se debe:

- Parar los escenarios VNX.
- Arrancar la imagen en modo directo con:

```
vnx --modify-rootfs /usr/share/vnx/filesystems/vnx_rootfs_lxc_ubuntu64-20.04-v025-vnxlab/
```

- Hacer login con root/xxxx e instalar los paquetes deseados.
- Parar el contenedor con:

```
halt -p
```

Arrancar de nuevo los escenarios VNX y comprobar que el software instalado ya 
está disponible.

Este método se puede utilizar para instalar, por ejemplo, `iperf3`, que no está
disponible en la imagen.

## 5. Partes opcionales

### Repositorio Docker privado 

Puede encontrar información detallada sobre la configuración de MicroK8s como
repositorio privado de Docker en [este documento](repo-privado-docker.md).

## Otras recomendaciones

- En el examen oral se pedirá arrancar el escenario desde cero, por lo que es
importante que todos los pasos para cumplir los requisitos mínimos estén
automatizados mediante uno o varios scripts. Si hay partes opcionales que se
configuran de forma manual, se deberán tener documentados todos los comandos
para ejecutarlos rápidamente mediante copia-pega. 

- Se recomienda dejar la parte de configuración de la calidad de servicio en la
KNF:access para el final, una vez que el resto del escenario esté funcionando
(túneles VXLAN, conectividad h1X-vcpe, DHCP, etc.).










