global with sharing class DefaultRequestLogger implements RequestLoggingInterface {
    private CalloutLogRedaction redaction;

    global DefaultRequestLogger() {
        this(new CalloutLogRedaction());
    }

    global DefaultRequestLogger(CalloutLogRedaction redaction) {
        this.redaction = redaction == null ? new CalloutLogRedaction() : redaction;
    }

    global void log(HttpRequest req, HttpResponse resp){
        LoggingLevel logLevel = getLoggingLevel(resp.getStatusCode());

        System.debug(logLevel, 'HTTP CALLOUT');
        System.debug(logLevel, req.getMethod() + ':' + redaction.redactUrlParameters(req.getEndpoint()));
        System.debug(logLevel, redaction.redactRequestBody(req));
        System.debug(logLevel, resp.getStatusCode() + ':' + resp.getStatus());
        for(String headerKey:resp.getHeaderKeys()){
            System.debug(logLevel, headerKey + ':' + redaction.redactHeaderValue(headerKey, resp.getHeader(headerKey)));
        }
        System.debug(logLevel, redaction.redactResponseBody(resp));
    }

    @testVisible
    private static LoggingLevel getLoggingLevel(Integer statusCode){
        if(statusCode >= 400){
            return LoggingLevel.ERROR;
        }else if(statusCode >= 300){
            return LoggingLevel.WARN;
        }else{
            return LoggingLevel.INFO;
        }
    }
}