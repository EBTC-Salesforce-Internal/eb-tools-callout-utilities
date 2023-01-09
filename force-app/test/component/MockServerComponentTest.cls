@isTest
public with sharing class MockServerComponentTest {
    @isTest
    public static void invalidResponse(){
        MockServer mockServer = new MockServer();
        Test.setMock(HttpCalloutMock.class, mockServer);

        try{
            HttpResponse resp = HttpRequestBuilder.get()
                    .endpoint('http://www.salesforce.com')
                    .send();

            Assert.fail();
        }catch(MockServer.MockServerException ex){
            Assert.areEqual('Unsupported operating mode.', ex.getMessage());
        }
    }

    @isTest
    public static void queuedResponse(){
        MockServer mockServer = MockServer.initQueued();

        mockServer.enqueue(HttpResponseBuilder.init().statusCode(200).build());

        HttpResponse resp = HttpRequestBuilder.get()
            .endpoint('http://www.salesforce.com')
            .send();

        Assert.areEqual(200, resp.getStatusCode());
    }

    @isTest
    public static void queuedResponse_Exception(){
        MockServer mockServer = MockServer.initQueued();

        try{
            HttpResponse resp = HttpRequestBuilder.get()
                    .endpoint('http://www.salesforce.com')
                    .send();

            Assert.fail();
        }catch(MockServer.MockServerException ex){
            Assert.areEqual('No mock response enqueued.', ex.getMessage());
        }
    }

    @isTest
    public static void matchedResponse(){
        MockServer mockServer = MockServer.initMatched();

        mockServer.whenRequest()
            .method('GET')
            .endpoint().doesNotContain('google')
            .header('Authorization').startsWith('Bearer')
            .body().isNull()
            .thenReturn()
            .statusCode(200);

        HttpResponse resp = HttpRequestBuilder.get()
                .endpoint('https://www.eidebailly.com')
                .header('Authorization', 'Bearer token')
                .send();

        Assert.areEqual(200, resp.getStatusCode());
    }

    @isTest
    public static void matchedResponse_None(){
        MockServer mockServer = MockServer.initMatched();

        try{
            HttpResponse resp = mockServer.respond(HttpRequestBuilder.init('GET').build());
            Assert.fail();
        }catch(MockServer.MockServerException ex){
            Assert.areEqual('No matching mock response found.', ex.getMessage());
        }
    }

    @isTest
    public static void matchedResponse_Multiple(){
        MockServer mockServer = MockServer.initMatched();

        mockServer.whenRequest()
            .method('GET')
            .thenReturn()
            .statusCode(200);

        mockServer.whenRequest()
            .header('Authorization').isNotNull()
            .thenReturn()
            .statusCode(200);

        try{
            HttpResponse resp = HttpRequestBuilder.get()
                    .header('Authorization', 'token')
                    .send();
            Assert.fail();
        }catch(MockServer.MockServerException ex){
            Assert.areEqual('Multiple matching mock responses found.', ex.getMessage());
        }
    }
}
