global with sharing class CalloutLoggingAdapter implements RequestLoggingInterface {
    global void log(HttpRequest req, HttpResponse resp) {
        LogHelper.logCallout(req, resp).publish();
    }
}