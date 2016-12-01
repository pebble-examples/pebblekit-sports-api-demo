package com.pebble.pebblekitsportsapidemo;

import android.content.Context;
import android.support.v7.app.ActionBar;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.os.Handler;
import android.support.v7.widget.SwitchCompat;
import android.view.View;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.Switch;
import android.widget.TextView;

import java.util.Date;

import com.getpebble.android.kit.Constants;
import com.getpebble.android.kit.PebbleKit;
import com.getpebble.android.kit.util.PebbleDictionary;
import com.getpebble.android.kit.util.SportsState;

public class MainActivity extends AppCompatActivity {

    private PebbleKit.PebbleDataReceiver mReceiver;
    private TextView statusView;
    private Handler handler = new Handler();
    private boolean displayPace = true;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        ActionBar actionBar = getSupportActionBar();
        actionBar.setTitle("PebbleKit Sports API Demo");

        final SportsState currentState = new SportsState();

        statusView = (TextView) findViewById(R.id.status);

        // Add Launch button listeners
        Button launchSports = (Button) findViewById(R.id.button_launch_sports);
        launchSports.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {
                PebbleKit.startAppOnPebble(getApplicationContext(), Constants.SPORTS_UUID);
            }

        });
        Button launchGolf = (Button) findViewById(R.id.button_launch_golf);
        launchGolf.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {
                PebbleKit.startAppOnPebble(getApplicationContext(), Constants.GOLF_UUID);
            }

        });

        // Add Configure Sports button listeners
        final Button sportsDummyData = (Button) findViewById(R.id.dummy_data_sports);
        sportsDummyData.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {
                final long startTime = System.currentTimeMillis();
                handler.post(new Runnable() {
                    @Override
                    public void run() {
                        double time = (double)(System.currentTimeMillis() - startTime) / 1000;
                        float accel = (float)Math.abs(-0.01 * Math.sin(time / 10) * 102);

                        currentState.setTimeInSec((int)time);
                        currentState.setDistance((float)(1.5 * time + Math.sin(time / 10)) / 1000);
                        currentState.setHeartBPM((byte)(90 + Math.sin(time / 10) * 30));
                        if (displayPace) {
                            currentState.setPaceInSec((int)((10 / (15 + Math.cos(time / 10))) * 1000));
                        } else {
                            currentState.setSpeed((float)(15 + Math.cos(time/10))/10 * (3600/1000));
                        }
                        currentState.setCustomLabel("Accel (in mG)");
                        currentState.setCustomValue(String.format("%.3f", accel));
                        currentState.synchronize(getApplicationContext());
                        handler.postDelayed(this, 1000);
                    }
                });
            }

        });

        final Switch sportsUnits = (Switch) findViewById(R.id.switch_sports_units);
        sportsUnits.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {

            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                // Switch units
                sportsUnits.setText("Units: " + (isChecked ? "Metric" : "Imperial"));

                byte value = (byte) (isChecked ?
                        Constants.SPORTS_UNITS_METRIC : Constants.SPORTS_UNITS_IMPERIAL);

                // Update watchapp
                PebbleDictionary out = new PebbleDictionary();
                out.addUint8(Constants.SPORTS_UNITS_KEY, value);
                PebbleKit.sendDataToPebble(getApplicationContext(), Constants.SPORTS_UUID, out);
            }

        });

        final Switch sportsPace = (Switch) findViewById(R.id.switch_sports_pace);
        sportsPace.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {

            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                // Switch metric
                sportsPace.setText("Pace or Speed: " + (isChecked ? "Speed" : "Pace"));
                displayPace = !isChecked;
            }

        });

        // Add Configure Golf button listeners
        final Button golfDummyData = (Button) findViewById(R.id.dummy_data_golf);
        golfDummyData.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {
                // Send some dummy data
                PebbleDictionary out = new PebbleDictionary();
                out.addString(Constants.GOLF_HOLE_KEY, "5");
                out.addString(Constants.GOLF_PAR_KEY, "4");
                out.addString(Constants.GOLF_BACK_KEY, "123");
                out.addString(Constants.GOLF_MID_KEY, "456");
                out.addString(Constants.GOLF_FRONT_KEY, "789");
                PebbleKit.sendDataToPebble(getApplicationContext(), Constants.GOLF_UUID, out);
            }

        });
    }

    @Override
    protected void onResume() {
        super.onResume();

        // Listen for button events
        if(mReceiver == null) {
            mReceiver = new PebbleKit.PebbleDataReceiver(Constants.SPORTS_UUID) {

                @Override
                public void receiveData(Context context, int id, PebbleDictionary data) {
                    // Always ACKnowledge the last message to prevent timeouts
                    PebbleKit.sendAckToPebble(getApplicationContext(), id);

                    // Get action and display as Toast
                    int state = data.getUnsignedIntegerAsLong(Constants.SPORTS_STATE_KEY).intValue();
                    statusView.setText(
                            (state == Constants.SPORTS_STATE_PAUSED ? "Resumed!" : "Paused!"));
                }

            };
            PebbleKit.registerReceivedDataHandler(getApplicationContext(), mReceiver);
        }
    }

    @Override
    protected void onPause() {
        super.onPause();

        try {
            unregisterReceiver(mReceiver);
        } catch(Exception e) {
            e.printStackTrace();
        } finally {
            mReceiver = null;
        }
    }
}
