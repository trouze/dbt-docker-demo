# Demo dbt-core on a Docker Image

This repo sets up a demo using the dbt Jaffle Shop data in Snowflake to demo an orchestration of a transformation using dbt that is containerized into a Docker container.

Assuming you've got Docker installed (likely using WSL2), clone this repo, change directory, and run the following commands. If you need to install Docker (and thus WSL), info can be found at the bottom.

Best practice is to initialize a dbt project and create the Dockerfile within that project directory. This will help avoid file path errors when generating the Docker image.

### Build Image

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
docker run --network=host --mount type=bind,source=/home/tyler/dev/dbt_project,target=/usr/app --mount type=bind,source=/home/tyler/.dbt/profiles.yml,target=/root/.dbt/profiles.yml dbt-demo-image debug
```

or

```
docker run --network=host --mount type=bind,source=/home/tyler/dev/dbt_docker,target=/usr/app --mount type=bind,source=/home/tyler/.dbt/profiles.yml,target=/root/.dbt/profiles.yml dbt-demo-image debug
```

### Installing WSL and Docker

If you're running Windows, you'll want to install WSL (Windows subsystem for Linux) in order to run Docker. WSL effectively runs a linux distro on your Windows machine. Most interaction with Linux will be using Bash/command line terminal. To get set up, we'll install a few things:

- WSL via [Microsoft's documentation](https://docs.microsoft.com/en-us/windows/wsl/install). Memorize your password!
- Restart your machine.
- [Windows Terminal](https://apps.microsoft.com/store/detail/windows-terminal/9N0DX20HK701?hl=en-us&gl=US)
- [Install Docker on WSL](https://docs.microsoft.com/en-us/windows/wsl/tutorials/wsl-containers)

### Running on a Cloud Platform (GCP in this example)

To make this easy, we'll install the gcloud SDK so we can use our local CLI to execute actions on Google Cloud Platform. To install the SDK, follow this [link](https://cloud.google.com/sdk/docs/install#deb) for Ubuntu distros.

What we'll do from here is setup an artifact registry on GCP and push our locally built Docker image to GCP where we're able to create a container instance and run dbt.

Enable the Artifact Registry API and create an Artifacts Repo if one doesn't exist already (can be done via cloud UI). Can also use the gcloud SDK:

```
gcloud artifacts repositories create dbt-docker-demo-repo --repository-format=docker \
--location=us-central1 --description="Docker repository"
```

Check that the repo exists:

```
gcloud artifacts repositories list
```

Configure authentication:

```
gcloud auth configure-docker us-central1-docker.pkg.dev
```

Tag the Image to stage it for upload to GCP

```
docker tag \
    dbt-snowflake-demo:latest \
    us-central1-docker.pkg.dev/dbt-docker-demo/dbt-docker-demo-repo/dbt-snowflake-demo:latest
```

Push Image to Registry

```
docker push us-central1-docker.pkg.dev/dbt-docker-demo/dbt-docker-demo-repo/dbt-snowflake-demo:latest
```

Create a Container based on the Docker Image in Cloud Run

```
gcloud run deploy --image us-central1-docker.pkg.dev/dbt-docker-demo/dbt-docker-demo-repo/dbt-snowflake-demo
```

Obviously in a production environment it will make sense to set up an orchestrator (e.g. GCP Composer) or a scheduler (e.g. Cloud Scheduler) to trigger a run and perform actions should something fail, but for the purposes of this demo we'll stop here.

If you're interested, you can schedule a container to be created/run [via this link](https://cloud.google.com/run/docs/triggering/using-scheduler).



### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
