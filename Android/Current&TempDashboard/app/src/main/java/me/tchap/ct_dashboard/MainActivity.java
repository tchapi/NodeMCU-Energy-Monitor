package me.tchap.ct_dashboard;

import android.app.Activity;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import org.eclipse.paho.client.mqttv3.MqttException;

import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;

public class MainActivity extends AppCompatActivity {

    private MQTTClient mMQTTClient;

    private TextView mTemperature;
    private TextView mPower;
    private TextView mActive;
    private View mActive1, mActive2;
    private Date mLastActive;
    private Timer mTimer;

    private boolean isPaused = false;

    private Button displayON;
    private Button displayOFF;
    private Button segmentON;
    private Button segmentOFF;
    private Button setTemperature;
    private Button setPower;
    private Button settings;
    private Button retry;

    private static int REFRESH_RATE = 30; // in secs

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mTemperature = (TextView) findViewById(R.id.temperature);
        mPower = (TextView) findViewById(R.id.power);
        mActive = (TextView) findViewById(R.id.active);
        mActive1 = findViewById(R.id.active1);
        mActive2 = findViewById(R.id.active2);

        displayON = (Button) findViewById(R.id.displayON);
        displayON.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mMQTTClient.sendMessageToSensor("on");
            }
        });

        displayOFF = (Button) findViewById(R.id.displayOFF);
        displayOFF.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mMQTTClient.sendMessageToSensor("off");
            }
        });

        segmentON = (Button) findViewById(R.id.segmentON);
        segmentON.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mMQTTClient.sendMessageToSensor("segment_on");
            }
        });

        segmentOFF = (Button) findViewById(R.id.segmentOFF);
        segmentOFF.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mMQTTClient.sendMessageToSensor("segment_off");
            }
        });

        setTemperature = (Button) findViewById(R.id.setTemperature);
        setTemperature.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mMQTTClient.sendMessageToSensor("dt");
            }
        });

        setPower = (Button) findViewById(R.id.setPower);
        setPower.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mMQTTClient.sendMessageToSensor("dw");
            }
        });

        settings = (Button) findViewById(R.id.settings);
        settings.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // Display the fragment as the main content.
                getFragmentManager().beginTransaction()
                        .replace(android.R.id.content, new SettingsFragment())
                        .addToBackStack("settings")
                        .commit();
            }
        });

        retry = (Button) findViewById(R.id.retry);
        retry.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {

                try {
                    mMQTTClient.connect();

                    mMQTTClient.subscribeToSensor(new CallbackInterface() {
                        public void execute(int power, float temperature) {
                            updateFigures(power, temperature);
                        }
                    });

                    launchWatchdog();

                } catch (MqttException e) {
                    mActive.setText("DISCONNECTED");
                    mActive1.setBackgroundColor(getResources().getColor(R.color.text));
                    mActive2.setBackgroundColor(getResources().getColor(R.color.text));
                    mActive.setTextColor(getResources().getColor(R.color.text));
                    retry.setVisibility(View.VISIBLE);
                    mTimer.cancel();
                    e.printStackTrace();
                }

            }
        });

        mMQTTClient = new MQTTClient(this);

        launchWatchdog();
    }

    public void launchWatchdog(){

        mTimer = new Timer();
        mLastActive = new Date();
        mTimer.scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        Date mt = new Date();
                        if (mLastActive.getTime() < (mt.getTime() - REFRESH_RATE * 1000) && !isPaused) {
                            mActive.setText("INACTIVE");
                            mActive1.setBackgroundColor(getResources().getColor(R.color.text));
                            mActive2.setBackgroundColor(getResources().getColor(R.color.text));
                            mActive.setTextColor(getResources().getColor(R.color.text));
                            System.out.println("No news ...");
                        }
                    }
                });
            }
        }, 0, REFRESH_RATE * 1000);
    }

    public void updateFigures(final int power, final float temperature) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mPower.setText(String.format("%d", power));
                mTemperature.setText(String.format("%.1f", temperature));
                mLastActive = new Date();
                mActive.setText("ACTIVE");
                mActive1.setBackgroundColor(getResources().getColor(R.color.active));
                mActive2.setBackgroundColor(getResources().getColor(R.color.active));
                mActive.setTextColor(getResources().getColor(R.color.active));
                System.out.println("Updated ! at " + mLastActive.toString());
                retry.setVisibility(View.GONE);
            }
        });
    }

    /*
    * Manages the back button in fragments stacks
    * */
    @Override
    public void onBackPressed() {

        if (getFragmentManager().getBackStackEntryCount() > 0) {
            getFragmentManager().popBackStack();
            getFragmentManager().beginTransaction().commit();
        } else {
            super.onBackPressed();
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        isPaused = false;
        if (mMQTTClient != null && !mMQTTClient.isConnected()) {
            try {
                mMQTTClient.connect();

                mMQTTClient.subscribeToSensor(new CallbackInterface() {
                    public void execute(int power, float temperature) {
                        updateFigures(power, temperature);
                    }
                });
            } catch (MqttException e) {
                Toast.makeText(this,"Impossible to connect to the broker. Please check the settings and that you have an available internet connection, and retry.", Toast.LENGTH_LONG).show();

                mActive.setText("DISCONNECTED");
                mActive1.setBackgroundColor(getResources().getColor(R.color.text));
                mActive2.setBackgroundColor(getResources().getColor(R.color.text));
                mActive.setTextColor(getResources().getColor(R.color.text));
                retry.setVisibility(View.VISIBLE);
                mTimer.cancel();
                e.printStackTrace();
            }
        }
    }


    @Override
    public void onPause() {
        super.onPause();
        isPaused = true;
        if (mMQTTClient != null) {
            try {
                mMQTTClient.disconnect();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
