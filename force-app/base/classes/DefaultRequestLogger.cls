global with sharing class DefaultRequestLogger implements RequestLoggingInterface {
    global void log(HttpRequest req, HttpResponse resp){
        LoggingLevel logLevel = getLoggingLevel(resp.getStatusCode());

        System.debug(logLevel, 'HTTP CALLOUT');
        System.debug(logLevel, req.getMethod() + ':' + req.getEndpoint());
        System.debug(logLevel, req.getBody());
        System.debug(logLevel, resp.getStatusCode() + ':' + resp.getStatus());
        for(String headerKey:resp.getHeaderKeys()){
            System.debug(logLevel, headerKey + ':' + resp.getHeader(headerKey));
        }
        System.debug(logLevel, resp.getBody());
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