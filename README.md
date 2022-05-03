# Demo dbt-core on a Docker Image

This repo sets up a demo using the dbt Jaffle Shop data in Snowflake to demo an orchestration of a transformation using dbt that is containerized into a Docker container.

Assuming you've got Docker installed (likely using WSL2), clone this repo, change directory, and run the following commands. If you need to install Docker (and thus WSL), info can be found at the below.

### Installing WSL and Docker

If you're running Windows, you'll want to install WSL (Windows subsystem for Linux) in order to run Docker. WSL effectively runs a linux distro on your Windows machine. Most interaction with Linux will be using Bash/command line terminal. To get set up, we'll install a few things:

- WSL via [Microsoft's documentation](https://docs.microsoft.com/en-us/windows/wsl/install). Memorize your password!
- Restart your machine.
- [Windows Terminal](https://apps.microsoft.com/store/detail/windows-terminal/9N0DX20HK701?hl=en-us&gl=US)
- [Install Docker on WSL](https://docs.microsoft.com/en-us/windows/wsl/tutorials/wsl-containers)

### Build Image

Best practice is to initialize a dbt project and create the Dockerfile within that project directory. This will help avoid file path errors when generating the Docker image.

The below command builds the docker image, we specify the adapter type. Here we show Databricks and Snowflake, but there are more. The period (.) at the end of the command specifies the path to the Dockerfile, if you've changed to the working directory that contains the Dockerfile and dbt project, this will work.

```
docker build --tag dbt-demo-image --target dbt-third-party --build-arg dbt_third_party=dbt-databricks .
```

or

```
docker build --tag dbt-demo-image --target dbt-snowflake .
```

### Run Image/Create Container

Either of the above commands will generate a Docker image set up to run dbt, we can then trigger (or schedule) a run of the dbt CLI through a `docker run` command.

```
docker run --network=host dbt-demo-image
```

or

```
docker run --network=host dbt-demo-image
```

This Dockerfile is configured with a bash `ENTRYPOINT` that will execute the commands in the `run.sh` file. If you don't wish for this behavior, you can change the `ENTRYPOINT` to be `dbt`. If this change is made, note that for testing purposes you can add a dbt command in the `docker run` command after `dbt-demo-image`, for example `ls` or `snapshot` or `run`. 

Additionally, we can change the mount/copy behavior of our `profiles.yml` file as well as our dbt project to be a part of the Docker image or not (default behavior is to copy profiles and project into the image). Copying the project and `profiles.yml` files makes the Docker image portable (e.g. run in the cloud). This will copy connection details into the Docker image, do understand that there are security implications in doing this.

If you wish to run docker more interactively across projects, you can add a couple args to the `docker run` command.

```
docker run --network=host --mount type=bind,source=/home/tyler/dev/dbt_project,target=/usr/app \
--mount type=bind,source=/home/tyler/.dbt/profiles.yml,target=/root/.dbt/profiles.yml \
dbt-demo-image debug
```

or

```
docker run --network=host --mount type=bind,source=/home/tyler/dev/dbt_docker,target=/usr/app \
--mount type=bind,source=/home/tyler/.dbt/profiles.yml,target=/root/.dbt/profiles.yml \
dbt-demo-image debug
```

### Running Docker in the Cloud (Azure in this case)
To run in the cloud (and set us up to schedule cloud runs), we can push our Docker image to a container registry, for Azure this is called Azure Container Registry.

First, you'll need the Azure CLI to interact with Azure components. If you're using WSL, you can open up a Ubuntu terminal window and simply run this command:
```
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

This will install the CLI, you can login with a simple ```az login``` command.

Then, we can simply follow the quickstart [here](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-azure-cli) to get our locally built image to Azure where we can run it. If you want to follow along here, we'll first create a resource group:

```
az group create --name dbt-snowflake-demo --location eastus
```

Create a container registry in that resource group:

```
az acr create --resource-group dbt-snowflake-demo --name dbtsnowflakedocker --sku Basic
```

Login to the container registry:

```
az acr login --name dbtsnowflakedocker
```

Name and tag our docker image for upload to the container registry:

```
docker tag dbt-snowflake-demo dbtsnowflakedocker.azurecr.io/dbtsnowflakeimage:v1
```

Push the container to the registry:

```
docker push dbtsnowflakedocker.azurecr.io/dbtsnowflakeimage:v1
```

Once you've pushed the image, you can go ahead and run an instance of your image using Azure Container Instance. From here, you could schedule an instance to be created on a schedule, or ran through some other means.

Additionally, to extend functionality and automation, you may set up a CI/CD pipeline that generates the Docker image on a pull request to this repository and pushes that image to the cloud image repository to be ran on next instantiation.

To run the image from Azure CLI one time, you can follow this [link](https://docs.microsoft.com/en-us/azure/container-instances/container-instances-quickstart) or run the command below:

```
az container create --resource-group dbt-snowflake-demo --name testdbtrun \
--registry-login-server dbtsnowflakedocker.azurecr.io \
--image dbtsnowflakedocker.azurecr.io/dbtsnowflakeimage:v1 \
--registry-username dbtsnowflakedocker --location eastus --ports 80 \
--protocol TCP --restart-policy Never --memory 1.5 --cpu 1 \
--os-type Linux --ip-address Private --registry-password <add password here>
```

It's lengthy, but we define necessary logic for the resources we'll need in order for our image to run successfully. This command should return JSON regarding the success (or lack thereof) of your instance run.

### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
