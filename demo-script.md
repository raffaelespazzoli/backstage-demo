# Demo Script

Once everything is installed correclty you will have a fill blown IDP with a couple of Golden Paths.
This demo script gives you an idea of what you can do with it.

## Application Onboarding

An application is comprised of several components, before we can start to deploy these components we need to onboard the application itself. This will provision the namespace and other resources needed to build and run components.
Navigate to backstage and click create component.

![Create Component](./media/create-component.png "Create Component")

select application template:

![Application Template](./media/application-template.png "Application Template")

populate the form as run the backstage template:

![Run Application Template](./media/run-application-template.png "Run Application Template")

This creates a new gitops repo for the new application component's manifests and a pull request to the approved-namespaces repos.
Impersonating the platform team, approve the pull request:

![Approved Namespaces PR](./media/approved-namespaces-pr.png "Approved Namespaces PR")

ArgoCD may take a minute to react to the new manifests.
In the meantime verify that the `myapp-gitops` repo has been created and it empty:

![Empty Myapp repo](./media/empty-myapp-repo.png "Empty myapp repo")

This is where all the component manifests will reside

Verify that the `myapp` SDLC namespace have been created:

![Myapp namespaces](./media/myapp-namespaces.png "Myapp namespaces")

Verify that in the build namespace pods for github action runner and argocd are created

![Myapp build pods](./media/myapp-build-pods.png "Myapp-build pods")

Verify that in the build namespaces some secrets needed for the build are automatically provisioned

![Myapp build secrets](./media/myapp-build-secrets.png "Myapp-build secrets")

If you accidentally delete those secrets, they will be re-provisioned.

Verify that you can access the new argocd instance for the `myapp` application at https://tenant-gitops-server-myapp-build.apps.${baseurl}/applications

![Myapp ArgoCD root app](./media/myapp-argocd-rootapp.png "Myapp ArgoCD root app")

Only the root app will be present. This app will create any resource that is added to the `./resouces` folder of the `myapp-gitops` repository. At the moment it's empty.

Now it's time to go back to Backstage and add one component to the the `myapp` application. Create a quarkus component:

![Create Quarkus Component](./media/create-quarkus-component.png "Create quarkus component")

![Create Quarkus Component Form one](./media/myquarkus-form-one.png "Create quarkus component Form one")

![Create Quarkus Component Form two](./media/myquarkus-form-one.png "Create quarkus component Form two")

Run the template. This will create a new `myquarkus` repository and a PR to the `myapp-gitops` repo adding the new manifests for this component.

Approve the PR to the `myapp-gitops` repository. This will be usually done by the developer team manager.

![My quarkus app PR](./media/myquarkus-app-pr.png "My quarkus app PR")

Verify that now the myapp ArgoCD is updated with new manifests:

![Myapp-gitops myquarkus manifests](./media/myapp-gitops-myquarkus-manifests.png "Myapp-gitops myquarkus manifests")

The apps at this point will not be healthy as the application image may not be built yet. Not that in this demo as soon as an applicaiton image is built, it is immediately pushed to production. This is obviously a simplification.

Verify and explore the new `myquarkus` repository, it contains a hello world quarkus service

![My quarkus repo](./media/myquarkus-repo.png "My quarkus repo")

In Backstage, navigate to the `myquarkus` component page, you should see the following:

![My quarkus component](./media/myquarkus-component-backstage.png "My quarkus component")

Notice that the SonarQube score should be already loaded. Click on one of the WebIDE links on the right:

![My quarkus WebIDE](./media/myquarkus-webide.png "My quarkus WebIDE")

Follow the DevWorkspace first-time instructions and you should get to a page in which you can edit the code and commit it back to the repository

![My quarkus VSCode](./media/myquarkus-vscode.png "My quarkus VSCode")

Now back to Backstage, verify that the `myquarkus` component is being built:

![My quarkus Backstage ci/cd](./media/myquarkus-backstage-ci-cd.png "My quarkus Backstage ci/cd")

Follow the links in the UI up to the GitHub Actions tab, verify that the build has been fully executed (this is a very minimal pipeline):

![My quarkus GitHub CI](./media/myquarkus-github-ci.png "My quarkus GitHub CI")

Go to Quay and verify that the image had been built and pushed:

![My quarkus Quay](./media/myquarkus-quay.png "My quarkus Quay")

Go back to Backstage and verify that the `myquarkus` component pods has been deployed

![My quarkus Pods](./media/myquarkus-pods.png "My quarkus Pods")

Verify that progressive delivery is enabled via ArgoRollouts. 
Run the following command

```shell
kubectl argo rollouts dashboard
```

and navigate to http://localhost:3100 and chose the `myapp-prod` namespace, you should see the following:

![My quarkus Argo Rollouts](./media/myquarkus-argorollouts.png "My quarkus Argo Rollouts")

Go back to Backstage and click on the metrics link

![My quarkus metrics link](./media/myquarkus-metrics-link.png "My quarkus metrics link")

TODO Add image of SRE metrics

Now it's time to add a database component to the `myapp` application.
Navigate back to Backstage and select the database component

![Database Component](./media/database-component.png "Database Component")

![Database Component Form](./media/database-component-form.png "Database Component Form")

This will create a PR to the `myapp-gitops` repository, approve the PR

![MyDB PR](./media/mydb-pr.png "MyDB PR")

refresh the `myapp` argocd root application and verify that new applications have been added:

![MyDB Argocd](./media/mydb-argocd.png "MyDB ArgoCD")

navigate to the cockroachDB console and verify that the instances for each environment have been created:

![MyDB CockroachDB instances](./media/mydb-cockroach-instances.png "MyDB CockroachDB instances")

navigate to the Data Services tab in the OpenShift console and verify that the instances are detected:

![MyDB DBaaS](./media/mydb-dbaas.png "MyDB DBaaS")

navigate to the Vault Console https://vault.apps.${base_domain}. Use this script to retrieve the root token

```shell
oc get secret vault-init -n vault -o jsonpath='{.data.root_token}' | base64 -d
```

verify that database connections are created for each of the database instances:

![MyDB Secret Engines](./media/mydb-secretengines.png "MyDB Secret Engines")

navigate to one of the roles in one of the database connections and verify that it is possible to generate credentials

![MyDB Generate Credentials](./media/mydb-generate-credentials.png "Generate Credentials")

Let's now configure to our myquarkus application to connect to the databases.
For the first time on this demo we have to actually write some code, so bear with us.
Checkout the code or access it via the WebIDE and perform the following changes:

in `src/main/java/io/raffa` create a file named `SantaClausService.java` file with the following content:

```java
package io.raffa;

import java.util.List;

import javax.enterprise.context.ApplicationScoped;
import javax.inject.Inject;
import javax.persistence.EntityManager;
import javax.transaction.Transactional;

@ApplicationScoped
public class SantaClausService {

    @Inject
    EntityManager em;

    @Transactional
    public List<Gift> getGifts() {
        return (List<Gift>) em.createQuery("select g from Gift g").getResultList();
    }
```

in `src/main/java/io.raffa` create a file named `Gift.java` with the following content: 

```java
package io.raffa;

import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;

@Entity
public class Gift {

    private Long id;
    private String name;

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator="giftSeq")
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
```

in the `pom.xml` file add the following dependencies: 

```xml
    <dependency>
      <groupId>io.quarkus</groupId>
      <artifactId>quarkus-hibernate-orm</artifactId>
    </dependency>
    <dependency>
      <groupId>io.quarkus</groupId>
      <artifactId>quarkus-jdbc-postgresql</artifactId>
    </dependency>
    <dependency>
      <groupId>io.quarkus</groupId>
      <artifactId>quarkus-jdbc-h2</artifactId>
    </dependency>
```

in scr/main/resources/application.properties add the following configuration

```properties
quarkus.devservices.enabled=false

quarkus.vault.url = https://vault.vault.svc:8200
quarkus.vault.tls.skip-verify = true

quarkus.vault.authentication.kubernetes.role = database-engine-admin

quarkus.vault.credentials-provider.mydb.credentials-role = mydb-${myquarkus.environment.suffix}-read-write
quarkus.vault.credentials-provider.mydb.credentials-mount = myapp-${myquarkus.environment.suffix}/mydb-${myquarkus.environment.suffix}

%dev.quarkus.datasource.db-kind = h2
%test.quarkus.datasource.db-kind = h2
%test.quarkus.datasource.jdbc.url=jdbc:h2:mem:default
%dev.quarkus.datasource.jdbc.url=jdbc:h2:mem:default

mydb.id=dummy
%remote_dev.mydb.id = 3582
%qa.mydb.id = 3584
%prod.mydb.id= 3583

quarkus.datasource.db-kind = postgresql
%remote_dev.quarkus.datasource.credentials-provider = mydb
%qa.quarkus.datasource.credentials-provider = mydb
%prod.quarkus.datasource.credentials-provider = mydb
quarkus.datasource.jdbc.url = jdbc:postgresql://free-tier4.aws-us-west-2.cockroachlabs.cloud:26257/defaultdb?sslmode=require&options=--cluster%3Dmyapp-${myquarkus.environment.suffix}-mydb-${myquarkus.environment.suffix}-${mydb.id}

# drop and create the database at startup (use `update` to only update the schema)
quarkus.hibernate-orm.database.generation=drop-and-create
```

Notice the `mydb.id`, you need to figure out this id on your own. One way to do it is to go to the cockroachdb console and see what the connection string should look like

![MyDB ID](./media/mydb-id.png "MyDB ID")

Commit this changes, this will trigger a build and roll-out of the app, verify that the pods are correct connected to the databases.