module.exports = {
  title: "pimatic-sabnzbd Device config schemas"
  SabnzbdSensor: {
    title: "SABNZBd Sensor device"
    description: "Sensor Device configuration"
    type: "object"
    extensions: ["xLink", "xOnLabel", "xOffLabel"]
    properties: {
      address:
        description: "The IP or address of your SABNZBd server"
        type: "string"
        default: "127.0.0.1"
      port:
        description: "The TCP/IP port of your SABNZBd server"
        type: "number"
        default: 8080
      key:
        description: "The API key for your SABNZBd server"
        type: "string"
        required: true
      interval:
        description: "Polling interval (seconds) for update requests"
        type: "number"
        default: 10
    }
  }
}