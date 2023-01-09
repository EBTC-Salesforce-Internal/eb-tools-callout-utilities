@isTest
public with sharing class HttpResponseBuilderTest {
    @isTest
    public static void verifyResponse(){
        HttpResponse resp = HttpResponseBuilder.init()
            .statusCode(200)
            .status('OK')
            .header('Content-Type', 'application/json')
            .body('{}')
            .build();

        System.assertEquals(resp.getStatusCode(), 200, 'Status code does not match.');
        System.assertEquals(resp.getStatus(), 'OK', 'Status does not match.');
        System.assert(resp.getHeaderKeys().contains('Content-Type'), 'Header not set.');
        System.assertEquals(resp.getHeader('Content-Type'), 'application/json', 'Header value does not match.');
        System.assertEquals(resp.getBody(), '{}', 'Body value does not match');
    }

    @isTest
    public static void verifyResponseBodyAsBlob(){
        HttpResponse resp = HttpResponseBuilder.init()
            .body(Blob.valueOf('Hello World'))
            .build();

        System.assertEquals(resp.getBody(), 'Hello World', 'Body value does not match');
    }
}
