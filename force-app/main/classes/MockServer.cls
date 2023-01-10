global class MockServer implements HttpCalloutMock{
    @testVisible private static MockServer mock;

    @testVisible private MockServer.Mode opMode;
    @testVisible private List<HttpRequest> requests = new List<HttpRequest>();
    @testVisible private List<HttpResponse> responseList = new List<HttpResponse>();
    @testVisible private List<ResponseSpec> responseSpecs = new List<ResponseSpec>();

    /**
     * Returns the initialized mock server. If a mock is not already defined, a
     * new mock is created and returned in its default configuration (QUEUE).
     * Also configures the test context to request against the mock server.
     */
    global static MockServer getInstance(){
        if(mock != null){
            return mock;
        }

        throw new MockServerException('No mock server initialized');
    }

    /**
     * Factory method for a Queued mock server.
     */
    global static MockServer initQueued(){
        return init(MockServer.Mode.QUEUE);
    }

    /**
     * Factory method for a Matched mock server.
     */
    global static MockServer initMatched(){
        return init(MockServer.Mode.MATCH);
    }

    /**
     * Initialize the mock server in the provided mode.
     * Also configures the test context to utilize the
     */
    private static MockServer init(MockServer.Mode mode){
        mock = new MockServer();
        mock.opMode = mode;

        if(Test.isRunningTest()){
            Test.setMock(HttpCalloutMock.class, MockServer.mock);
        }

        return mock;
    }

    /**
     * Clear the request cache in preparation for a new test scenario.
     */
    global void clear(){
        this.requests = new List<HttpRequest>();
    }

    /**
     * Reset the mock server to its initial state, removing all history and configuration.
     */
    global void reset(){
        this.requests = new List<HttpRequest>();
        this.responseList = new List<HttpResponse>();
        this.responseSpecs = new List<ResponseSpec>();
    }

    /**
     * Required method for the HttpCalloutMock interface. This method executes
     * matching logic and returns the appropriate response.
     */
    global HttpResponse respond(HttpRequest req){
        //Store the request
        requests.add(req);

        if(opMode == Mode.QUEUE){
            return getQueueResponse();
        }

        if(opMode == Mode.MATCH){
            return getMatchResponse(req);
        }

        throw new MockServer.MockServerException('Unsupported operating mode.');
    }

    /**
     * Capture the HTTP request made to the mock server sequentially.
     * Allows for verification of the request structure.
     */
    global HttpRequest takeRequest(){
        if(mock.requests.isEmpty()){
            return null;
        }

        return mock.requests.remove(0);
    }

    //These methods are used in the QUEUE operating mode.

    global void enqueue(HttpResponse resp){
        if(opMode != Mode.QUEUE){
            throw new MockServerException('Mock Server is not in QUEUE mode');
        }

        mock.responseList.add(resp);
    }

    private HttpResponse getQueueResponse(){
        if(responseList.isEmpty()){
            throw new MockServerException('No mock response enqueued.');
        }

        return responseList.remove(0);
    }

    //These methods are used in the MATCH operating mode.

    global RequestSpec whenRequest(){
        if(opMode != Mode.MATCH){
            throw new MockServerException('Mock Server is not in MATCH mode');
        }
        return new RequestSpec();
    }

    private HttpResponse getMatchResponse(HttpRequest request){
        ResponseSpec target;

        for(ResponseSpec spec:responseSpecs){
            if(spec.verifyMatch(request)){
                if(target != null){
                    throw new MockServer.MockServerException('Multiple matching mock responses found.');
                }

                target = spec;
            }
        }

        if(target == null){
            throw new MockServer.MockServerException('No matching mock response found.');
        }

        return target.build();
    }

    /**
     * Used to define the request being made to the mock server when in MATCH mode.
     */
    global class RequestSpec{
        private String method;
        private List<EndpointRequestSpec> endpointSpecs;
        private List<HeaderRequestSpec> headerSpecs;
        private List<BodyRequestSpec> bodySpecs;

        @testVisible
        private RequestSpec(){
            this.endpointSpecs = new List<EndpointRequestSpec>();
            this.headerSpecs = new List<HeaderRequestSpec>();
            this.bodySpecs = new List<BodyRequestSpec>();
        }

        global RequestSpec method(String method){
            this.method = method;
            return this;
        }

        global EndpointRequestSpec endpoint(){
            EndpointRequestSpec endpointSpec = new EndpointRequestSpec(this);
            endpointSpecs.add(endpointSpec);
            return endpointSpec;
        }

        global HeaderRequestSpec header(String headerKey){
            HeaderRequestSpec headerSpec = new HeaderRequestSpec(this, headerKey);
            headerSpecs.add(headerSpec);
            return headerSpec;
        }

        global BodyRequestSpec body(){
            BodyRequestSpec bodySpec = new BodyRequestSpec(this);
            bodySpecs.add(bodySpec);
            return bodySpec;
        }

        global ResponseSpec thenReturn(){
            return new ResponseSpec(this);
        }
    }

    global virtual class RequestSpecElement{
        private RequestSpec requestSpec;

        private MockServer.CompareMode mode;
        private String compareVal;

        public RequestSpecElement(RequestSpec requestSpec){
            this.requestSpec = requestSpec;
        }

        global RequestSpec isNull(){
            return operation(CompareMode.IS_NULL, null);
        }

        global RequestSpec isNotNull(){
            return operation(CompareMode.NOT_NULL, null);
        }

        global RequestSpec isEqualTo(String compareVal){
            return operation(CompareMode.EQUAL, compareVal);
        }

        global RequestSpec isNotEqualTo(String compareVal){
            return operation(CompareMode.NOT_EQUAL, compareVal);
        }

        global RequestSpec contains(String compareVal){
            if(compareVal == null){
                throw new MockServerException('Cannot use \'contains\' operator with a null value');
            }
            return operation(CompareMode.CONTAINS, compareVal);
        }

        global RequestSpec doesNotContain(String compareVal){
            if(compareVal == null){
                throw new MockServerException('Cannot use \'doesNotContain\' operator with a null value');
            }
            return operation(CompareMode.NOT_CONTAINS, compareVal);
        }

        global RequestSpec startsWith(String compareVal){
            if(compareVal == null){
                throw new MockServerException('Cannot use \'startsWith\' operator with a null value');
            }
            return operation(CompareMode.STARTS_WITH, compareVal);
        }

        global RequestSpec doesNotStartWith(String compareVal){
            if(compareVal == null){
                throw new MockServerException('Cannot use \'doesNotStartWith\' operator with a null value');
            }
            return operation(CompareMode.NOT_STARTS_WITH, compareVal);
        }

        global RequestSpec endsWith(String compareVal){
            if(compareVal == null){
                throw new MockServerException('Cannot use \'endsWith\' operator with a null value');
            }
            return operation(CompareMode.ENDS_WITH, compareVal);
        }

        global RequestSpec doesNotEndWith(String compareVal){
            if(compareVal == null){
                throw new MockServerException('Cannot use \'doesNotEndWith\' operator with a null value');
            }
            return operation(CompareMode.NOT_ENDS_WITH, compareVal);
        }

        /**
         * This stores the compare operation for later use.
         */
        @testVisible
        private RequestSpec operation(MockServer.CompareMode mode, String compareVal){
            this.mode = mode;
            this.compareVal = compareVal;
            return requestSpec;
        }

        /**
         * This method executes the comparison operation.
         */
        @testVisible
        private Boolean verifyValue(String value){
            switch on mode {
                when IS_NULL {
                    return String.isBlank(value);
                }
                when NOT_NULL {
                    return String.isNotBlank(value);
                }
                when EQUAL {
                    return value == compareVal;
                }
                when NOT_EQUAL {
                    return value != compareVal;
                }
                when CONTAINS {
                    return value != null && value.contains(compareVal);
                }
                when NOT_CONTAINS {
                    return value == null || !value.contains(compareVal);
                }
                when STARTS_WITH {
                    return value != null && value.startsWith(compareVal);
                }
                when NOT_STARTS_WITH {
                    return value == null || !value.startsWith(compareVal);
                }
                when ENDS_WITH {
                    return value != null && value.endsWith(compareVal);
                }
                when NOT_ENDS_WITH {
                    return value == null || !value.endsWith(compareVal);
                }
                when else{
                    throw new MockServer.MockServerException('Unsupported comparison operator');
                }
            }
        }
    }

    global class EndpointRequestSpec extends RequestSpecElement{
        public EndpointRequestSpec(RequestSpec requestSpec){
            super(requestSpec);
        }
    }

    global class HeaderRequestSpec extends RequestSpecElement{
        private String headerKey;

        public HeaderRequestSpec(RequestSpec requestSpec, String headerKey){
            super(requestSpec);
            this.headerKey = headerKey;
        }
    }

    global class BodyRequestSpec extends RequestSpecElement{
        public BodyRequestSpec(RequestSpec requestSpec){
            super(requestSpec);
        }
    }

    /**
     * Extension of HttpResponseBuilder used for mapping responses in
     * the mock web server.
     */
    global class ResponseSpec extends HttpResponseBuilder{
        private RequestSpec requestSpec;

        @testVisible
        private ResponseSpec(RequestSpec requestSpec){
            super();
            this.requestSpec = requestSpec;
            mock.responseSpecs.add(this);
        }

        @testVisible
        private Boolean verifyMatch(HttpRequest request){
            if(requestSpec.method != null && requestSpec.method != request.getMethod()){
                return false;
            }
            for(EndpointRequestSpec endpointSpec:requestSpec.endpointSpecs){
                if(endpointSpec.verifyValue(request.getEndpoint()) == false){
                    return false;
                }
            }
            for(HeaderRequestSpec headerSpec:requestSpec.headerSpecs){
                if(headerSpec.verifyValue(request.getHeader(headerSpec.headerKey)) == false){
                    return false;
                }
            }
            for(BodyRequestSpec bodySpec:requestSpec.bodySpecs){
                if(bodySpec.verifyValue(request.getBody()) == false){
                    return false;
                }
            }

            return true;
        }
    }

    global class MockServerException extends Exception{}

    global enum Mode {
        QUEUE,
        MATCH
    }

    private enum CompareMode{
        IS_NULL,
        NOT_NULL,
        EQUAL,
        NOT_EQUAL,
        CONTAINS,
        NOT_CONTAINS,
        STARTS_WITH,
        NOT_STARTS_WITH,
        ENDS_WITH,
        NOT_ENDS_WITH
    }
}
