# epr-frontend-performance-tests

A JMeter based test runner for the CDP Platform.

- [Licence](#licence)
  - [About the licence](#about-the-licence)

## Build

Test suites are built automatically by the [.github/workflows/publish.yml](.github/workflows/publish.yml) action whenever a change are committed to the `main` branch.
A successful build results in a Docker container that is capable of running your tests on the CDP Platform and publishing the results to the CDP Portal.

## Run

The performance test suites are designed to be run from the CDP Portal.
The CDP Platform runs test suites in much the same way it runs any other service, it takes a docker image and runs it as an ECS task, automatically provisioning infrastructure as required.

## Local Testing

### Launch the required services using epr-re-ex-service

Ensure you have the latest version of [epr-re-ex-service](https://github.com/DEFRA/epr-re-ex-service) checked out.

```
docker compose -f compose.yml --profile all up -d
```

This will launch the required services for local testing.

### Run performance tests

Download [JMeter](https://jmeter.apache.org/download_jmeter.cgi) and launch the JMeter GUI. Load the `epr-backend-test.jmx` file from this repository into JMeter.

Enable "Local User Defined Variables" and disable "Environment User Defined Variables" to run the tests. Ensure to disable "Local User Defined Variables" and re-enable "Environment User Defined Variables" when you are done..


## Licence

THIS INFORMATION IS LICENSED UNDER THE CONDITIONS OF THE OPEN GOVERNMENT LICENCE found at:

<http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3>

The following attribution statement MUST be cited in your products and applications when using this information.

> Contains public sector information licensed under the Open Government licence v3

### About the licence

The Open Government Licence (OGL) was developed by the Controller of Her Majesty's Stationery Office (HMSO) to enable
information providers in the public sector to license the use and re-use of their information under a common open
licence.

It is designed to encourage use and re-use of information freely and flexibly, with only a few conditions.
