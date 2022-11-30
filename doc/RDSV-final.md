# RDSV/SDNV Trabajo final

- [RDSV/SDNV Trabajo final](#rdsvsdnv-trabajo-final)
  - [Resumen](#resumen)
  - [Entrega de resultados](#entrega-de-resultados)
  - [Desarrollo del trabajo](#desarrollo-del-trabajo)
    - [1. Repositorios propios](#1-repositorios-propios)

## Resumen

![Visión global del escenario](img/nfv-lab-figura3.drawio.png)

*Fig. 3. Visión global del escenario*

![Visión detallada del escenario](img/nfv-lab-figura4.drawio.png)

*Fig. 4. Visión detallada del escenario*

## Entrega de resultados

En los apartados siguientes encontrará algunos marcados con (P). Deberá 
responder a esos apartados en un documento memoria-p4.pdf.

Suba a través del Moodle un único fichero zip que incluya el fichero pdf y
los scripts modificados y creados para el trabajo.

## Desarrollo del trabajo
### 1. Repositorios propios
Crear un repositorio rdsv-final y copiar ahí 

Hacer una cuenta gratuita en Docker Hub https://hub.docker.com

```
cd img/vnf-img
docker login -u <cuenta>  # pedirá password la primera vez

# A continuación, añadir un fichero README.txt en el contenedor 
# añadiendo una sentencia COPY  al Dockerfile

# Después, crear el contenedor
docker build -t <cuenta>/vnf-img .

# Y subirlo a Docker Hub
docker push <cuenta>/vnf-img

cd ../..
```

Modificar helm

```
cd helm
# cambiar en los ficheros values.yaml de cada helm chart el valor de
image:
  repository: educaredes/vnf-img --> <cuenta>/vnf-img

# y actualizar 
cd ..
helm package helm/accesschart
helm package helm/cpechart
helm repo index --url https://cuenta-git.github.io/nfv-final/ .
```









