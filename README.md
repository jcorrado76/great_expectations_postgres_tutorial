This will contain the great expectations tutorial that was put together by StartDataEngineering [here](https://www.youtube.com/watch?v=MhIN_7NPgNU&list=WL&index=7&t=5s).

First, you need to spin up the docker container holding the Postgres database by running:
```shell
make postgres_docker
```


Which will run the Makefile that is contained here.

Then, you need to log into that database instance using `pgcli`.

You can install `pgcli` with the command:
```shell
brew install pgcli
```


Then, establish a connection using `pgcli` with:
```shell
pgcli -h localhost -p 5432 -U sde -d data_quality
```


Then, enter the password from the Makefile.

Now, we'll create a new schema, a new table and insert some dummy data into that table.

Run the commands located in the `insert_dummy_data.sql` file.

Then, you can display what you've done so far by running:
```postgresql
select * from app.order;
```


Now, exit out of that `pgcli` connection with `\q`.

Then, initialize your great expectations deployment by making sure you're in the root folder of your project directory, and running:

`great_expectations init`

Now, you'll be guided through a series of questions to set up your first Datasource.

Since we've already set up our Postgres Datasource, you can select `Y` to configure the Postgres database we set up previously.

Make sure you've installed `sqlalchemy` into your environment prior to doing this set up, or else the setup will exit when you've selected a relational database.

Now that we've specified Postgres, great expectations is also going to look for an installation of `psycopg2-binary` in your environment, so make sure
you run:

`pip install psycopg2-binary`

Make sure to select a Relational database during the setup, and specify a Postgres database.

Then, you'll be prompted to set up a name for the Datasource connection.

Here, you should put `data_quality` again, so it matches the name of the database we created in Postgres.

Then, you will be prompted for the:
* host - localhost
* port - 5432
* username - sde
* password - the password specified in Makefile
* database - data_quality

So that great expectations can store all these credentials in a configuration file. 

This information will not be version controlled, as it will be stored in a file called `uncomitted/config_variables.yml`

Then, you will be asked if you want to profile the data in your database to create some expectation stubs. 

Say `Y` here, and then select the table that was detected (should be `app.order`)

Then, you will be prompted to name the new suite, which you should specify:

`app.order.error`

The expectations will be saved in a JSON file at:

`expectations/app/order/error.json`

So, say yes to this and then build the Data Docs.

Then, you'll be given the option to view your stubbed expectations, which should open in your default browser.

You should see all the stubbed (and overfitted) expectations in these docs.

## Editing Expectations
Now, we're going to edit the set of expectations in our suite.

You can do this interactively in a Jupyter notebook by running:

`great_expectations suite edit app.order.error`

This will spawn a Jupyter instance that's local to this project, in which you can edit your suite interactively by editing
the Jupyter notebook cells. 

Go into the Jupyter notebook, and run the cells under the `Edit Your Expectation Suite` - these just connect to your Datasource
and show some example data.

When you've taken a look at the data for which we're editing this suite, you can go down to the `Create & Edit Expectations` section.

Here, you'll see your table-level expectations (one per cell), which you can delete or edit in the Jupyter Notebook.

And you'll also see your Column Expectations, which you can delete or edit in the Jupyter Notebook.

Remove all of the stubbed expectations (we don't need any of them), by deleting the contents of all of the cells.

Then, you could add a new expectation for requiring every value in the `customer_id` column to be distinct with the expectation:

```
batch.expect_column_distinct_values_to_be_in_set(
    column='customer_id', 
    value_set={
        "customer_1",
        "customer_2"
    }
)
```

Then, you'd run that cell.
You should be able to see whether that check was true or false.
For our case, it should run true.

Then, to overwrite the old expectation file with the JSON file corresponding to this new one, just run the cells underneath
`Save & Review Your Expectations`.

When you run that last cell, there's a call to `context.open_data_docs(validation_result_identifier)`, which will essentially
open the results page from the local site in your browser with your new checks.

You should now see only the single expectation we just created, and the fact that it ran successfully.

Now, we'd like to run this expectation.

You do that by placing it inside of a checkpoint.

You can use the great_expectations CLI to create a new checkpoint like this:

`great_expectations checkpoint new first_checkpoint app.order.error`

When you run this, great expectations is going to prompt you for the datasource you'd like to use.
You just need to select the `app.order` table, similarly to how we did it above.

Then, you can list your checkpoints to ensure that you've successfully created it like this:

`great_expectations checkpoint list`

And, you can run it with:

`great_expectations checkpoint run first_checkpoint`

And you should see the output of running your checks in your terminal.

The output of your run of your checkpoint is stored in your uncommitted folder, since you don't want those results to be 
version controlled. 

You'll see a folder structure with your validations in it that looks like:

`validations/app/order/error/[your checkpoint runs here]`

In production, you'd want to store your validations in some data base or artifact store.

Now, we need to understand what exactly is happening when you run this checkpoint.

If you look inside the `checkpoints/first_checkpoint.yml` file, you'll see that there's a `validation_operator_name: action_list_operator`
line, which essentially corresponds to an entry in your main configuration YAML file, which points to 
several actions that will occur when you fire off the checkpoint.

In this `first_checkpoint.yml` file, you'll just see what operator is being used, and then what batches were involved in the current checkpoint.

Now, if you go back into the `great_expectations.yml` file, you'll see under `validation_operators`, you should have an operator
that's called an `action_list_operator`.

In there, you'll see a list of actions, under `action_list`.

Some of these actions will be:
* `store_validation_result`, which uses the class `StoreValidationResultAction`
* `store_evaluation_params`, which uses the class `StoreEvaluationParameterAction`
* `update_data_docs`, which uses the class `UpdateDataDocsAction`

And these are the actions that are run when you run the `action_list_operator`, which is called by the checkpoint we created.

In addition, in this YAML file, you'll find a section for `stores:`, which basically tells you the configuration for where your
results are stored. If you're using a local, file deployment of great_expectations, you will have, under your `validations_store`,
a `base_directory` field that points to a folder where your validation results will be stored.

Essentially, we want to change this so that we're not pointing a directory for files, and we're pointing to our database. 

What you n eed to do, is add a new entry under `stores:`, with the contents:

```yaml
validations_postgres_store:
  class_name: ValidationStore
  store_backend:
    class_name: DatabaseStoreBackend
    credentials: ${data_quality}
```

Note, that in that YAML code, we made a reference to the credentials for our `data_quality` data source by referring to it with
`${data_quality}`. So, this step assumes you've set up that data source with appropriate credentials.

With these settings, great expectations will store the results of your validations in the database, and not in your local filesystem.

Then, you should be able to run:

`great_expectations checkpoint run first_checkpoint`

When you run that, a table will be automatically created:

`public.ge_validations_store`

And you should be able to log back into your database instance, and run:

`select * from public.ge_validations_store;`

And you'll see the results from your validations in JSON format.

To display text nicely in your PGCLI client, run:

`\x on;`

This will display your JSON nicely. 


Now, for the last exercise, we'll see what happens when we insert a row that does not pass our expectations inside our Postgres database.

Log into your post gres instance the same way we did before.

And run the command:

```postgresql
INSERT INTO app.order (order_id, customer_id, status)
VALUES ('order_3', 'customer_5', 'on-route');
```

Then, you can exit your PGCLI client, and run:

```shell
great_expectations checkpoint run first_checkpoint
```

And you should see your validation fail, which is what we expect since the only expectation we have is that 
the distinct values for our `custom_id` is one of the values `['customer_1','customer_2']`.

You can then verify the stored validation result telling you that your validation failed by signing back intoy our PGCLI client,
and running:

```postgresql
SELECT * FROM public.ge_validations_store;
```

The second result you'll see in this table will contain a field: `"success": false`, which is what we expect.