# RDSV/SDNV Repositorio privado de imágenes Docker en MicroK8s

## Introducción

Tener un registro privado de imágenes Docker en nuestro entorno o cluster de
Kubernetes puede mejorar significativamente la productividad y acelerar el
desarrollo al reducir el tiempo dedicado a cargar y descargar imágenes de Docker
desde repositorios públicos accesibles desde Internet como Docker Hub. Una vez
que este servicio de registro privado esté disponible en un entorno Kubernetes,
permitirá cargar imágenes Docker personalizadas que podrán ser usadas
directamente por las aplicaciones o los servicios desplegados en el propio
entorno Kubernetes sin la necesidad de acceder a repositorios públicos.

## Pasos a seguir

Pasos para instalar y trabajar con el registro privado de imágenes Docker en
MicroK8s:

1.	En primer lugar, en MicroK8s (desde la máquina virtual RDSV-K8S) hay que
habilitar el servicio “registry” dedicado para el registro de imágenes Docker
mediante el siguiente comando:

```
$ microk8s enable registry
```

2.	Por defecto, el servicio “registry” se expone en el endpoint
“localhost:32000”. Si queremos hacer uso de este servicio privado de imágenes
Docker desde una máquina diferente al servidor que gestiona Kubernetes, es
necesario indicar el endpoint asociado como confiable en el fichero
“/etc/docker/daemon.json” de la siguiente manera:

```
{
"insecure-registries" : ["<IP_MicroK8s_server>:32000"]
}
```

Siendo `<IP_MicroK8s_server>` la IP de acceso al servidor de Kubernetes (en
nuestro caso la IP de la máquina virtual RDSV-K8S 192.168.56.11).

Posteriormente, reinicie el servicio de Docker en la máquina externa para cargar
la nueva configuración mediante el comando siguiente:

```
$ sudo systemctl restart docker
```

>Nota: Si construimos la imagen Docker en la misma máquina virtual RDSV-K8S que
>gestiona el entorno de Kubernetes, no hace falta seguir los pasos anteriores.

3.	Las imágenes Docker que se construyan deben etiquetarse con el endpoint
asociado al registro privado antes de cargarlas en él. Para ello, suponiendo que
nos encontramos en el mismo directorio donde se encuentra el archivo Dockerfile
a partir del cuál queremos construir una imagen Docker que cargaremos en nuestro
registro privado, ejecutamos el siguiente comando:

```
$ docker build . -t <IP_MicroK8s_server>:32000/<nombre_imagen>:<version>
```

Siendo <IP_MicroK8s_server> la IP de acceso al servidor de Kubernetes (en
nuestro caso la IP de la máquina virtual RDSV-K8S 192.168.56.11),
<nombre_imagen> el nombre que queremos que tenga la imagen Docker en el
repositorio y <version> la versión de la misma (por ejemplo, latest).

4.	Ahora que la imagen Docker ha sido correctamente etiquetada y que apunta al
registro correspondiente, podemos cargarla en el registro de la siguiente forma:

```
$ docker push <IP_MicroK8s_server>:32000/<nombre_imagen>:<version>
```

5.	Para verificar si las imágenes de Docker se han creado y almacenado
correctamente en el repositorio, puede usar la API de registro de Docker, que le
permite listar las imágenes de Docker disponibles en cualquier momento en el
registro privado de Kubernetes con la siguiente solicitud:

```
$ curl http:// <IP_MicroK8s_server>:32000/v2/_catalog
```

Y debería generar un resultado similar al siguiente:

```
{"repositories": ["<image_name>"]}
```

6.	Además, puedes consultar la lista de las diferentes versiones asociadas a
una imagen específica de Docker cargada en el repositorio con la siguiente
solicitud:

```
$ curl http:// <IP_MicroK8s_server>:32000/v2/<image_name>/tags/list
```

Que debería generar un resultado similar al siguiente:

```
{"name":"<image_name>","tags": ["<version>"]}
```

7.	Una vez configurado el registro de imágenes Docker en MicroK8s y cargada una
imagen concreta en él, para que la imagen sea utilizada por un servicio
desplegado en Kubernetes, siempre hay que apuntar a ella indicando además el
registro privado donde se encuentra de la siguiente manera:
<IP_MicroK8s_server>:32000/<nombre_imagen>

>Nota: En la práctica, hay que cambiar el fichero values.yaml de los Helm Charts
>que empaquetan nuestras KNFs para que ahora usen una imagen precargada en el
>repositorio de imágenes Docker. Para ello, modificar de forma adecuada los
>parámetros “repository” y “tag” asociados a la nueva imagen en el fichero
>values.yaml.


Pasos para borrar imágenes del registro privado de imágenes Docker en MicroK8s: 

COMING SOON!








