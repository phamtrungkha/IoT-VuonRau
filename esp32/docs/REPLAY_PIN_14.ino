#define RELAY_PIN 15

void setup() {
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW); // tắt relay
}

void loop() {
  digitalWrite(RELAY_PIN, HIGH);  // bật
  delay(2000);

  digitalWrite(RELAY_PIN, LOW); // tắt
  delay(2000);
}