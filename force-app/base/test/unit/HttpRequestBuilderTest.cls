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
    public static void verifyRequestMethods_NamedCredential(){
        Test.startTest();

        HttpRequest req = HttpRequestBuilder.init('GET')
            .namedCredential('namedCredential')
            .endpoint('/sample/test')
            .timeout(120000)
            .header('Authorization','Bearer token')
            .body('{}')
            .compressed(true)
            .build();

        Test.stopTest();

        System.assertEquals(req.getEndpoint(), 'callout:namedCredential/sample/test', 'Endpoint does not match');
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

    @isTest
    public static void requestMultiPart_Simple(){
        HttpRequest req;

        Test.startTest();

        req = HttpRequestBuilder.init('POST')
            .multipartBody()
            .addField('type','sampleType')
            .addField('value', 'application/json', '{}')
            .setMultipartBody()
            .build();

        Test.stopTest();

        String contentType = req.getHeader('Content-Type');
        Assert.isTrue(contentType.contains('multipart/form-data; boundary='));
        String boundary = contentType.substringAfter('boundary=');

        String expBody = '--' + boundary + '\r\n';
        expBody += 'Content-Disposition: form-data; name="type"\r\n\r\nsampleType\r\n';
        expBody += '--' + boundary + '\r\n';
        expBody += 'Content-Disposition: form-data; name="value"\r\nContent-Type: application/json\r\n\r\n{}\r\n';
        expBody += '--' + boundary + '--';
        Assert.areEqual(expBody, req.getBody());
    }

    @isTest
    public static void requestMultiPart_Complex(){
        HttpRequest req;

        Test.startTest();

        req = HttpRequestBuilder.init('POST')
            .multipartBody()
            .addFile('file00', 'noEqual', Blob.valueOf('Hello World!'))
            .addFile('file', 'oneEqual', 'text/plain', Blob.valueOf('This is fun'))
            .addFile('file3', 'twoEqual', Blob.valueOf('Goodbye World'))
            .addField('value', 'application/json', '{}')
            .setMultipartBody()
            .build();

        Test.stopTest();

        String contentType = req.getHeader('Content-Type');
        Assert.isTrue(contentType.contains('multipart/form-data; boundary='));
        String boundary = contentType.substringAfter('boundary=');

        String expBody = '--' + boundary + '\r\n';
        //part has no injected space, value has no added boundary
        expBody += 'Content-Disposition: form-data; name="file00"; filename="noEqual"\r\nContent-Type: application/octet-stream\r\n\r\nHello World!\r\n';
        expBody += '--' + boundary + '\r\n';
        //part has one injected space, value has \r added boundary
        expBody += 'Content-Disposition: form-data; name="file"; filename="oneEqual"\r\nContent-Type: text/plain \r\n\r\nThis is fun\r\n';
        expBody += '--' + boundary + '\r\n';
        //part has two injected space, value has \r\n added boundary
        expBody += 'Content-Disposition: form-data; name="file3"; filename="twoEqual"\r\nContent-Type: application/octet-stream  \r\n\r\nGoodbye World\r\n';
        expBody += '--' + boundary + '\r\n';
        //part has two injected spaces due to the encoding requirement
        expBody += 'Content-Disposition: form-data; name="value"\r\nContent-Type: application/json  \r\n\r\n{}\r\n';
        expBody += '--' + boundary + '--';
        Assert.areEqual(expBody, req.getBody());
    }

    @isTest
    public static void requestLogging(){
        HttpRequestBuilder.enableLogging(new DefaultRequestLogger());

        HttpRequest req = HttpRequestBuilder.get()
            .endpoint('https://www.google.com')
            .build();

        HttpResponse resp = HttpResponseBuilder.init()
            .statusCode(200)
            .build();

        new DefaultRequestLogger().log(req, resp);
    }

    @isTest
    public static void verifyLoggingLevels(){
        Assert.areEqual(LoggingLevel.ERROR, DefaultRequestLogger.getLoggingLevel(404));
        Assert.areEqual(LoggingLevel.WARN, DefaultRequestLogger.getLoggingLevel(301));
        Assert.areEqual(LoggingLevel.INFO, DefaultRequestLogger.getLoggingLevel(200));
    }
}