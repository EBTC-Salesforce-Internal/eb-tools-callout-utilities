@isTest
public with sharing class MockServerTest {
    @isTest
    public static void getInstance(){
        MockServer.mock = null;

        try{
            MockServer mock = MockServer.getInstance();
            Assert.fail();
        }catch(MockServer.MockServerException ex){
            Assert.areEqual('No mock server initialized', ex.getMessage());
        }
    }

    @isTest
    public static void initServerQueue(){

        MockServer mock = MockServer.initQueued();

        Assert.areEqual(MockServer.Mode.QUEUE, mock.opMode);

        Assert.areEqual(mock, MockServer.getInstance());
    }

    @isTest
    public static void initServerMatch(){
        MockServer mock = MockServer.initMatched();

        Assert.areEqual(MockServer.Mode.MATCH, mock.opMode);
    }

    @isTest
    public static void clear(){
        MockServer mock = MockServer.initQueued();

        mock.requests.add(HttpRequestBuilder.init('GET').build());
        mock.responseList.add(HttpResponseBuilder.init().build());
        mock.responseSpecs.add(new MockServer.ResponseSpec(new MockServer.RequestSpec()));

        mock.clear();

        Assert.areEqual(0, mock.requests.size());
        Assert.areNotEqual(0, mock.responseList.size());
        Assert.areNotEqual(0, mock.responseSpecs.size());
    }

    @isTest
    public static void reset(){
        Test.startTest();

        MockServer mock = MockServer.initQueued();

        mock.requests.add(HttpRequestBuilder.init('GET').build());
        mock.responseList.add(HttpResponseBuilder.init().build());
        mock.responseSpecs.add(new MockServer.ResponseSpec(new MockServer.RequestSpec()));

        mock.reset();

        Test.stopTest();

        Assert.areEqual(0, mock.requests.size());
        Assert.areEqual(0, mock.responseList.size());
        Assert.areEqual(0, mock.responseSpecs.size());
    }

    @isTest
    public static void takeRequest(){
        MockServer mock = MockServer.initQueued();

        HttpRequest req = mock.takeRequest();

        Assert.isNull(req);

        mock.requests.add(HttpRequestBuilder.init('GET').build());

        req = mock.takeRequest();

        Assert.areNotEqual(null, req);
        Assert.areEqual(0, mock.requests.size());
    }

    @isTest
    public static void enqueue(){
        MockServer mockServer = MockServer.initQueued();

        mockServer.enqueue(HttpResponseBuilder.init().build());

        Assert.areEqual(1, mockServer.responseList.size());
    }

    @isTest
    public static void enqueue_MatchMode(){
        MockServer mockServer = MockServer.initMatched();

        try{
            mockServer.enqueue(HttpResponseBuilder.init().build());

            Assert.fail();
        }catch(MockServer.MockServerException ex){
            Assert.areEqual('Mock Server is not in QUEUE mode', ex.getMessage(), 'Unexpected exception thrown.');
        }
    }

    @isTest
    public static void whenRequest(){
        MockServer mockServer = MockServer.initMatched();

        mockServer.whenRequest().thenReturn();

        Assert.areEqual(1, mockServer.responseSpecs.size());
    }

    @isTest
    public static void whenRequest_QueueMode(){
        MockServer mockServer = MockServer.initQueued();

        try{
            mockServer.whenRequest();

            Assert.fail();
        }catch(MockServer.MockServerException ex){
            Assert.areEqual('Mock Server is not in MATCH mode', ex.getMessage(), 'Unexpected exception thrown.');
        }
    }

    @isTest
    public static void respond_NoOp(){
        MockServer mockServer = new MockServer();

        try{
            mockServer.respond(HttpRequestBuilder.init('GET').build());

            Assert.fail();
        }catch(MockServer.MockServerException ex){
            Assert.areEqual('Unsupported operating mode.', ex.getMessage());
        }
    }

    @isTest
    public static void respond_Queue(){
        MockServer mockServer = MockServer.initQueued();

        mockServer.enqueue(HttpResponseBuilder.init().statusCode(200).build());

        HttpResponse resp = mockServer.respond(HttpRequestBuilder.init('GET').build());

        Assert.areEqual(200, resp.getStatusCode());
    }

    @isTest
    public static void respond_Queue_NoneQueued(){
        MockServer mockServer = MockServer.initQueued();

        try{
            mockServer.respond(HttpRequestBuilder.init('GET').build());

            Assert.fail();
        }catch(MockServer.MockServerException ex){
            Assert.areEqual('No mock response enqueued.', ex.getMessage());
        }
    }

    @isTest
    public static void respond_Match(){
        MockServer mockServer = MockServer.initMatched();

        mockServer.whenRequest()
            .method('GET')
            .endpoint().doesNotContain('google')
            .header('Authorization').startsWith('Bearer')
            .body().isNull()
            .thenReturn()
            .statusCode(200);

        HttpResponse resp = mockServer.respond(
            HttpRequestBuilder.init('GET')
            .endpoint('https://www.eidebailly.com')
            .header('Authorization', 'Bearer token')
            .build());

        Assert.areEqual(200, resp.getStatusCode());
    }

    @isTest
    public static void respond_NoMatch(){
        MockServer mockServer = MockServer.initMatched();

        try{
            HttpResponse resp = mockServer.respond(HttpRequestBuilder.init('GET').build());
            Assert.fail();
        }catch(MockServer.MockServerException ex){
            Assert.areEqual('No matching mock response found.', ex.getMessage());
        }
    }

    @isTest
    public static void respond_MultipleMatch(){
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
            HttpResponse resp = mockServer.respond(HttpRequestBuilder.init('GET').header('Authorization', 'token').build());
            Assert.fail();
        }catch(MockServer.MockServerException ex){
            Assert.areEqual('Multiple matching mock responses found.', ex.getMessage());
        }
    }

    @isTest
    public static void requestSpecElementVerifyValue_Unsupported(){
        MockServer.RequestSpecElement elem = new MockServer.RequestSpecElement(null);
        try{
            elem.verifyValue('test');
            Assert.fail();
        }catch(MockServer.MockServerException ex){
            Assert.areEqual('Unsupported comparison operator', ex.getMessage());
        }
    }

    @isTest
    public static void requestSpecElementVerifyValue_Null(){
        MockServer.RequestSpecElement elem = new MockServer.RequestSpecElement(null);
        elem.isNull();
        Assert.isTrue(elem.verifyValue(null));
        Assert.isTrue(elem.verifyValue(''));
        Assert.isTrue(elem.verifyValue(' '));
        Assert.isFalse(elem.verifyValue('a'));
    }

    @isTest
    public static void requestSpecElementVerifyValue_NotNull(){
        MockServer.RequestSpecElement elem = new MockServer.RequestSpecElement(null);
        elem.isNotNull();
        Assert.isFalse(elem.verifyValue(null));
        Assert.isFalse(elem.verifyValue(''));
        Assert.isFalse(elem.verifyValue(' '));
        Assert.isTrue(elem.verifyValue('null'));
    }

    @isTest
    public static void requestSpecElementVerifyValue_Equals(){
        MockServer.RequestSpecElement elem = new MockServer.RequestSpecElement(null);
        elem.isEqualTo(null);
        Assert.isTrue(elem.verifyValue(null));
        Assert.isFalse(elem.verifyValue(''));
        Assert.isFalse(elem.verifyValue(' '));
        Assert.isFalse(elem.verifyValue('null'));

        elem.isEqualTo('test');
        Assert.isTrue(elem.verifyValue('test'));
        Assert.isFalse(elem.verifyValue('test '));
        Assert.isFalse(elem.verifyValue(' test'));
        Assert.isFalse(elem.verifyValue(' test '));
        Assert.isFalse(elem.verifyValue(''));
        Assert.isFalse(elem.verifyValue(null));
    }

    @isTest
    public static void requestSpecElementVerifyValue_NotEquals(){
        MockServer.RequestSpecElement elem = new MockServer.RequestSpecElement(null);
        elem.isNotEqualTo(null);
        Assert.isFalse(elem.verifyValue(null));
        Assert.isTrue(elem.verifyValue(''));
        Assert.isTrue(elem.verifyValue(' '));
        Assert.isTrue(elem.verifyValue('null'));

        elem.isNotEqualTo('test');
        Assert.isFalse(elem.verifyValue('test'));
        Assert.isTrue(elem.verifyValue('test '));
        Assert.isTrue(elem.verifyValue(' test'));
        Assert.isTrue(elem.verifyValue(' test '));
        Assert.isTrue(elem.verifyValue(''));
        Assert.isTrue(elem.verifyValue(null));
    }

    @isTest
    public static void requestSpecElementVerifyValue_Contains(){
        MockServer.RequestSpecElement elem = new MockServer.RequestSpecElement(null);
        try{
            elem.contains(null);
            Assert.fail();
        }catch(MockServer.MockServerException ex){
            Assert.areEqual('Cannot use \'contains\' operator with a null value', ex.getMessage());
        }

        elem.contains('test');
        Assert.isTrue(elem.verifyValue('test'));
        Assert.isTrue(elem.verifyValue('test '));
        Assert.isTrue(elem.verifyValue(' test'));
        Assert.isTrue(elem.verifyValue(' test '));
        Assert.isFalse(elem.verifyValue(''));
        Assert.isFalse(elem.verifyValue(null));
    }

    @isTest
    public static void requestSpecElementVerifyValue_doesNotContain(){
        MockServer.RequestSpecElement elem = new MockServer.RequestSpecElement(null);
        try{
            elem.doesNotContain(null);
            Assert.fail();
        }catch(MockServer.MockServerException ex){
            Assert.areEqual('Cannot use \'doesNotContain\' operator with a null value', ex.getMessage());
        }

        elem.doesNotContain('test');
        Assert.isFalse(elem.verifyValue('test'));
        Assert.isFalse(elem.verifyValue('test '));
        Assert.isFalse(elem.verifyValue(' test'));
        Assert.isFalse(elem.verifyValue(' test '));
        Assert.isTrue(elem.verifyValue(''));
        Assert.isTrue(elem.verifyValue(null));
    }

    @isTest
    public static void requestSpecElementVerifyValue_StartsWith(){
        MockServer.RequestSpecElement elem = new MockServer.RequestSpecElement(null);
        try{
            elem.startsWith(null);
            Assert.fail();
        }catch(MockServer.MockServerException ex){
            Assert.areEqual('Cannot use \'startsWith\' operator with a null value', ex.getMessage());
        }

        elem.startsWith('test');
        Assert.isTrue(elem.verifyValue('test'));
        Assert.isTrue(elem.verifyValue('test '));
        Assert.isFalse(elem.verifyValue(' test'));
        Assert.isFalse(elem.verifyValue(' test '));
        Assert.isFalse(elem.verifyValue(''));
        Assert.isFalse(elem.verifyValue(null));
    }

    @isTest
    public static void requestSpecElementVerifyValue_doesNotStartWith(){
        MockServer.RequestSpecElement elem = new MockServer.RequestSpecElement(null);
        try{
            elem.doesNotStartWith(null);
            Assert.fail();
        }catch(MockServer.MockServerException ex){
            Assert.areEqual('Cannot use \'doesNotStartWith\' operator with a null value', ex.getMessage());
        }

        elem.doesNotStartWith('test');
        Assert.isFalse(elem.verifyValue('test'));
        Assert.isFalse(elem.verifyValue('test '));
        Assert.isTrue(elem.verifyValue(' test'));
        Assert.isTrue(elem.verifyValue(' test '));
        Assert.isTrue(elem.verifyValue(''));
        Assert.isTrue(elem.verifyValue(null));
    }

    @isTest
    public static void requestSpecElementVerifyValue_EndsWith(){
        MockServer.RequestSpecElement elem = new MockServer.RequestSpecElement(null);
        try{
            elem.endsWith(null);
            Assert.fail();
        }catch(MockServer.MockServerException ex){
            Assert.areEqual('Cannot use \'endsWith\' operator with a null value', ex.getMessage());
        }

        elem.endsWith('test');
        Assert.isTrue(elem.verifyValue('test'));
        Assert.isFalse(elem.verifyValue('test '));
        Assert.isTrue(elem.verifyValue(' test'));
        Assert.isFalse(elem.verifyValue(' test '));
        Assert.isFalse(elem.verifyValue(''));
        Assert.isFalse(elem.verifyValue(null));
    }

    @isTest
    public static void requestSpecElementVerifyValue_doesNotEndWith(){
        MockServer.RequestSpecElement elem = new MockServer.RequestSpecElement(null);
        try{
            elem.doesNotEndWith(null);
            Assert.fail();
        }catch(MockServer.MockServerException ex){
            Assert.areEqual('Cannot use \'doesNotEndWith\' operator with a null value', ex.getMessage());
        }

        elem.doesNotEndWith('test');
        Assert.isFalse(elem.verifyValue('test'));
        Assert.isTrue(elem.verifyValue('test '));
        Assert.isFalse(elem.verifyValue(' test'));
        Assert.isTrue(elem.verifyValue(' test '));
        Assert.isTrue(elem.verifyValue(''));
        Assert.isTrue(elem.verifyValue(null));
    }

    @isTest
    public static void responseSpecVerifyTest(){
        MockServer mockServer = MockServer.initMatched();

        mockServer.whenRequest()
            .method('GET')
            .endpoint().doesNotContain('google')
            .header('Authorization').startsWith('Bearer')
            .body().isNull()
            .thenReturn()
            .statusCode(200);

        MockServer.ResponseSpec respSpec = mockServer.responseSpecs[0];

        Assert.isFalse(respSpec.verifyMatch(
            HttpRequestBuilder.init('POST')
                .endpoint('https://www.eidebailly.com')
                .header('Authorization', 'Bearer token')
                .build()), 'Didn\'t fail on method.');
        Assert.isFalse(respSpec.verifyMatch(
            HttpRequestBuilder.init('GET')
                .endpoint('https://www.google.com')
                .header('Authorization', 'Bearer token')
                .build()), 'Didn\'t fail on endpoint.');
        Assert.isFalse(respSpec.verifyMatch(
            HttpRequestBuilder.init('GET')
                .endpoint('https://www.eidebailly.com')
                .header('Authorization', 'token')
                .build()), 'Didn\'t fail on header value.');
        Assert.isFalse(respSpec.verifyMatch(
            HttpRequestBuilder.init('GET')
                .endpoint('https://www.eidebailly.com')
                .header('Authorization', 'Bearer token')
                .body('Hello World')
                .build()), 'Didn\'t fail on body value.');
        Assert.isTrue(respSpec.verifyMatch(
            HttpRequestBuilder.init('GET')
                .endpoint('https://www.eidebailly.com')
                .header('Authorization', 'Bearer token')
                .build()));
    }

}
