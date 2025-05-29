import ballerina/http;
import ballerinax/rabbitmq;

final http:Client httpClient = check new ("localhost:9091/processor");
final rabbitmq:Client rabbitmqClient = check new ("localhost", 5672);
