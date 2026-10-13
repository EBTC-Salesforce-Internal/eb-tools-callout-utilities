# EB Tools - Callout Utilities

## Overview

The EB Tools - Callout Utilities package provides helpers to streamline development and testing of Salesforce callouts. Its builders use method chaining to improve readability.

An optional companion package adds structured event logging.

Choose one Callout Utilities lane. For structured callout logging, install Callout Utilities, EB Tools - Logging, then Callout Logging.

| Package                      | Stable                                                                                                 | Beta                                                                                                         |
| ---------------------------- | ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| EB Tools - Callout Utilities | 0.1.0.10: [Install](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t5G000004PzeBQAS) | 0.2.0.1 (beta): [Install](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tUk000002xcbBIAQ) |
| EB Tools - Logging           | 0.3.0.3: [Install](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tUk000002sN89IAE)  |                                                                                                              |
| EB Tools - Callout Logging   | Not available                                                                                          | 0.1.0.2 (beta): [Install](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tUk000002xccnIAA) |

EB Tools - Logging is optional for basic callout utilities. The Callout Logging adapter does not have a stable release yet.

## Installation

To install a package with Salesforce CLI, use its subscriber package version ID from the table above:

```
sf package install --package <subscriber-package-version-id> --target-org <alias or username>
```

## Usage

### Http Request Builder

There are several factory methods on the HttpRequestBuilder used to initialize the request specification with one of two required pieces of information: the method. Methods include `get()`, `post()`, `patch()`, `put()`, and `del()` (delete is a reserved word in Apex). `HttpRequestBuilder.init(String method)` can also be used.

Methods on the builder assign values to the method, headers, and body of the request, as well as other request parameters such as the timeout, compression, and client certificate name to use for encryption.

Invoking `build()` will return the constructed HttpRequest.

Invoking `send()` will execute the request against the remote server or mock and return the response.

#### Multi-part Post Body

Invoking `multipartBody()` configures the request to send the body as Form-Data. The appropriate Content-Type header is set with the calculated boundary value. The format of the boundary is `-----xUNIX_TIMESTAMPx-----`. The returned value is a MultipartBodyBuilder instance on which you can call methods to add fields or files.

The `addField()` method takes a name, value (String) and (optionally) a content type.

The `addFile()` method takes a name, filename, value (Blob), and (optionally) content type. If no content type is provided, the default is `application/octet-stream`.

Set the body back to the request by invoking `setMultipartBody()`. This will return the related HttpRequestBuilder instance.

#### Request Logging

The `RequestLoggingInterface` provides a programmatic hook to access the HttpRequest and HttpResponse objects. A default implementation of this interface is available in the `DefaultRequestLogger` class. In order to enable this functionality, invoke `enableLogging()` method with a `RequestLoggingInterface` instance.

`DefaultRequestLogger` writes the request method, endpoint, and body, plus the response status, headers, and body, to the Apex debug log. Redaction is opt-in and can be configured for the built-in loggers:

```apex
EBTLS.CalloutLogRedaction redaction = new EBTLS.CalloutLogRedaction()
	.header('Authorization')
	.header('Set-Cookie')
	.urlParameter('access_token')
	.bodyPattern('Bearer [A-Za-z0-9._-]+');

EBTLS.HttpRequestBuilder.enableLogging(new EBTLS.DefaultRequestLogger(redaction));
```

Header names are matched case-insensitively and matching values become `[REDACTED]`. Each regex match in request and response text bodies becomes `[REDACTED]`. Bodies that cannot be represented byte-for-byte as text are masked entirely. Apex does not distinguish a UTF-8 Blob from an equivalent String, so those bodies follow the text regex rules. Redaction changes log output only, not the callout.

Configured URL parameter names are matched case-insensitively in the query string, including percent-encoded names. Every matching value becomes `[REDACTED]`; other parameters and URL fragments are preserved.

Implementations of `RequestLoggingInterface` outside the built-in loggers must apply their own redaction. The structured adapter can be configured the same way:

To publish structured callout logs, install all three packages and enable the adapter before sending a request:

```apex
EBTLS.HttpRequestBuilder.enableLogging(new EBTLS.CalloutLoggingAdapter(redaction));
```

The `CalloutLoggingAdapter` publishes a `Log_Event__e` event for each completed callout response through EB Tools - Logging. It redacts configured URL query parameters, response headers, and both bodies; EB Tools - Logging currently records a placeholder instead of request header values.

### Mock Server

The MockServer class is a universal implementation of HttpCalloutMock interface that allows the test to determine the behavior exhibited by the endpoint at runtime. It allows for more responsive testing as the test functionality is determined within the test definition instead of a separate class. Additionally, it captures the requests such that we can validate the construction and composition of the web request being sent out from Salesforce.

#### Initialization

Use the static `MockServer.initQueued()` or `MockServer.initMatched()` to initialized the Mock Server. Initialization creates the singleton instance of the MockServer and sets it as the active mock in the test context (`Test.setMock()`).

Once initialized, you can retarget the active mock server using `MockServer.getInstance()`.

#### Queue Mode

When in `QUEUE` mode, the MockServer will return the staged responses in a predefined sequence. Add a response to the queue using the instance method `enqueue(HttpResponse resp)`. These will be returned in a FIFO (first in - first out) sequence as reqeusts are made to the mock.

If no mock responses are available, a `MockServerException` will be thrown.

> This mode is useful in unit tests where the number of potential requests is limited (usually one, sometimes two) and responses vary greatly to accomodate the needs of the test.

#### Match Mode

When in `MATCH` mode, the MockServer will return the correct staged response based on criteria evaluated against the request. In this way, the number of requests does not need to be predetermined, only the total potential responses that can be returned.

Request specs are created using the `whenRequest()` function chain to define request criteria such as method, endpoint, headers, and body content. After request criteria has been defined, invoking `thenReturn` registers the spec and returns an instance of ResponseSpec.

If a request doesn't meet the criteria of any of the RequestSpecs, a `MockServerException` is thrown. If a request meets the criteria of more than one RequestSpec, a `MockServerException` is thrown.

> This mode is useful in larger unit or regression testing scenarios. Initialize the MockServer and configure its responses inside each test method. `@testSetup` shares test records with test methods, but Apex static state and `Test.setMock()` registration do not persist between test methods.

##### RequestSpec

The RequestSpec object has for properties that can be used to define criteria:

- `method(String method)` - This method sets the appropriate method, always using an 'equal' operator.
- `endpoint()` - Allows multiple conditions evaluated against the request endpoint.
- `header(String headerName)` - Allows multiple conditions evaluated against the header defined as a parameter.
- `body()` - Allows multiple conditions evaluated against the body of the request.

Each of these specifications use string-based values, performing literal comparisons (no wildcards). Operations include:

- Is Blank/Not Blank (null, empty, and whitespace-only values are blank)
- Equal/Not Equal
- Contains/Does Not Contain
- Starts With/Does Not Start With
- Ends With/Does Not End With

##### ResponseSpec

Upon invoked `thenReturn()` you are provided an instance of ResponseSpec. Invoking the methods inherited from the HttpResponseBuilder define the response. Methods include the following and function similar to those found on the [HttpResponse](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_http_httpresponse.htm):

- status(String status)
- statusCode(Integer statusCode)
- header(String headerName, String headerValue)
- body(String body)
- body(Blob body)

> There is no need for any further calls after the response is defined, the `thenReturn()` function registers the specifications with the MockSever.

#### Take Request

To allow better testing of HttpRequests, the MockServer stores all requests made to a list that can be retrieve the requests in sequence using `takeRequest()`. Utilize the `clear()` function to reset this list.

#### Clear and Reset Functions

Each test method has its own MockServer execution state. Within a test method, `clear()` removes captured requests only; `reset()` removes captured requests and staged queue/match responses while keeping the current operating mode.

## What are the EB Tools packages?

The EB Tools packages are a collection of helpful components, utilities, and frameworks to promote use of best practices in Salesforce.com development and configuration.

- [EDHU Trigger Framework](https://bitbucket.org/eidebailly/edhu)
- [Dynamic Lookup Component](https://bitbucket.org/eidebailly/dynamiclookup2)
