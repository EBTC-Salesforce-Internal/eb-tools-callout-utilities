@isTest
public with sharing class HttpRequestBuilderTest {
    @isTest
    public static void verifyRequestMethods(){
        Test.startTest();

        HttpRequest req = HttpRequestBuilder.init('GET')
            .endpoint('http://www.google.com')
            .timeout(120000)
            .header('Authorization','Bearer token')
            .body('{}')
            .compressed(true)
            .build();

        Test.stopTest();

        System.assertEquals(req.getEndpoint(), 'http://www.google.com', 'Endpoint does not match');
        System.assertEquals(req.getHeader('Authorization'), 'Bearer token', 'Header does not match');
        System.assertEquals(req.getCompressed(), true, 'Compression attribute does not match');
    }

    @isTest
    public static void requestMethods(){
        HttpRequest req;

        Test.startTest();

        req = HttpRequestBuilder.get().build();
        System.assertEquals(req.getMethod(), 'GET', 'GET method not specified.');

        req = HttpRequestBuilder.post().build();
        System.assertEquals(req.getMethod(), 'POST', 'POST method not specified.');

        req = HttpRequestBuilder.put().build();
        System.assertEquals(req.getMethod(), 'PUT', 'PUT method not specified.');

        req = HttpRequestBuilder.patch().build();
        System.assertEquals(req.getMethod(), 'PATCH', 'PATCH method not specified.');

        req = HttpRequestBuilder.del().build();
        System.assertEquals(req.getMethod(), 'DELETE', 'DELETE method not specified.');

        Test.stopTest();
    }

    @isTest
    public static void requestBodyBlob(){
        HttpRequest req;

        Test.startTest();

        req = HttpRequestBuilder.init('GET')
            .body(Blob.valueOf('Hello World'))
            .build();

        Test.stopTest();

        System.assertEquals(req.getBodyAsBlob(), Blob.valueOf('Hello World'), 'Unable to get the body as a blob.');
    }

    @isTest
    public static void requestBodyDocument(){
        HttpRequest req;

        Test.startTest();

        req = HttpRequestBuilder.init('GET')
            .body(new Dom.Document())
            .build();

        Test.stopTest();

        System.assertNotEquals(req.getBodyDocument(), null, 'Document not returned.');
    }
}