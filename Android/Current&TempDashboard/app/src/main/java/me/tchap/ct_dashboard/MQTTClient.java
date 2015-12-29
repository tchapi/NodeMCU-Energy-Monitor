package me.tchap.ct_dashboard;

/**
 * Current & Temp Dashboard
 * Created by tchap on 28/12/15.
 */
import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.MqttTopic;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;

import java.util.StringTokenizer;

public class MQTTClient implements MqttCallback {

    MqttClient mClient;
    MqttConnectOptions connOpt;
    CallbackInterface mCallbackInterface;

    SharedPreferences sharedPref;

    public MQTTClient(MainActivity activity) {
        sharedPref = PreferenceManager.getDefaultSharedPreferences(activity);
    }

    /**
     *
     * connectionLost
     * This callback is invoked upon losing the MQTT connection.
     *
     */
    @Override
    public void connectionLost(Throwable t) {
        System.out.println("Connection lost!");
        // code to reconnect to the broker :
        try {
            connect();
            subscribeToSensor(mCallbackInterface);
        } catch (MqttException e) {
            e.printStackTrace();
        }
    }

    /**
     *
     * deliveryComplete
     * This callback is invoked when a message published by this client
     * is successfully received by the broker.
     *
     */
    @Override
    public void deliveryComplete(IMqttDeliveryToken token){
        try {
            System.out.println("Delivery complete");
        } catch (Exception e){
            e.printStackTrace();
        }
    }

    /**
     *
     * messageArrived
     * This callback is invoked when a message is received on a subscribed topic.
     *
     */
    @Override
    public void messageArrived(String topic, MqttMessage message) throws Exception {

        /*System.out.println("-------------------------------------------------");
        System.out.println("| Topic:" + topic);
        System.out.println("| Message: " + new String(message.getPayload()));
        System.out.println("-------------------------------------------------");
        */
        // id=%s&w=%d&t=%.2f&h=%d
        StringTokenizer tokens = new StringTokenizer(new String(message.getPayload()), "&");
        String id = tokens.nextToken();
        String power = tokens.nextToken().substring(2);
        String temperature = tokens.nextToken().substring(2);
        String heap = tokens.nextToken();

        if(mCallbackInterface != null) {
            mCallbackInterface.execute(Integer.valueOf(power),Float.valueOf(temperature));
        }
    }

    public void sendMessageToSensor(String data) {

        // setup topic
        MqttTopic topic = mClient.getTopic(sharedPref.getString("pref_sensor", ""));

        int pubQoS = 2;
        MqttMessage message = new MqttMessage(data.getBytes());
        message.setQos(pubQoS);
        message.setRetained(false);

        // Publish the message
        System.out.println("Publishing to topic \"" + topic + "\" qos " + pubQoS + " with message " + message.toString());
        MqttDeliveryToken token = null;
        try {
            // publish message to broker
            token = topic.publish(message);
            // Wait until the message has been delivered to the broker
            token.waitForCompletion();
            Thread.sleep(100);
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    public void subscribeToSensor(CallbackInterface ci){

        // setup topic
        int subQoS = 2;

        try {
            mClient.subscribe(sharedPref.getString("pref_data", ""), subQoS);
            mCallbackInterface = ci;
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
     *
     *
     */
    public void connect() throws MqttException {
        connOpt = new MqttConnectOptions();

        connOpt.setCleanSession(true);
        connOpt.setKeepAliveInterval(3600);
        connOpt.setConnectionTimeout(3600);
        connOpt.setUserName(sharedPref.getString("pref_username", ""));
        connOpt.setPassword(sharedPref.getString("pref_password", "").toCharArray());

        // Connect to Broker

        mClient = new MqttClient(sharedPref.getString("pref_url", "") + ":" + sharedPref.getString("pref_port", "1883"), sharedPref.getString("pref_client", ""), new MemoryPersistence());
        mClient.setCallback(this);
        mClient.connect(connOpt);
        System.out.println("Connected to " + sharedPref.getString("pref_url", ""));
        sendMessageToSensor("force");

    }

    public void disconnect() {
        // disconnect
        try {
            // wait to ensure subscribed messages are delivered
            Thread.sleep(5000);
            mClient.disconnect();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public boolean isConnected() {
        return mClient != null && mClient.isConnected();
    }
}