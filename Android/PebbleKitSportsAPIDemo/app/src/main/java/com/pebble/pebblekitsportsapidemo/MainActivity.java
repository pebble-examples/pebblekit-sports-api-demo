package com.pebble.pebblekitsportsapidemo;

import android.content.Context;
import android.support.v7.app.ActionBar;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.support.v7.widget.SwitchCompat;
import android.view.View;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;

import com.getpebble.android.kit.Constants;
import com.getpebble.android.kit.PebbleKit;
import com.getpebble.android.kit.util.PebbleDictionary;

public class MainActivity extends AppCompatActivity {

    private PebbleKit.PebbleDataReceiver mReceiver;
    private TextView statusView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        ActionBar actionBar = getSupportActionBar();
        actionBar.setTitle("PebbleKit Sports API Demo");

        statusView = (TextView)findViewById(R.id.status);

        // Add Launch button listeners
        Button launchSports = (Button)findViewById(R.id.button_launch_sports);
        launchSports.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {
                PebbleKit.startAppOnPebble(getApplicationContext(), Constants.SPORTS_UUID);
            }

        });
        Button launchGolf = (Button)findViewById(R.id.button_launch_golf);
        launchGolf.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {
                PebbleKit.startAppOnPebble(getApplicationContext(), Constants.GOLF_UUID);
            }

        });

        // Add Configure Sports button listeners
        final Button sportsDummyData = (Button)findViewById(R.id.dummy_data_sports);
        sportsDummyData.setOnClickListener(new View.OnClickListener() {

            @Override
            public void onClick(View v) {
                // Send some dummy data
                PebbleDictionary out = new PebbleDictionary();
                out.addString(Constants.SPORTS_TIME_KEY, "12:52");
                out.addString(Constants.SPORTS_DISTANCE_KEY, "23.8");
                PebbleKit.sendDataToPebble(getApplicationContext(), Constants.SPORTS_UUID, out);
            }

        });

        final Switch sportsUnits = (Switch)findViewById(R.id.switch_sports_units);
        sportsUnits.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {

            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                // Switch units
                sportsUnits.setText("Units: " + (isChecked ? "Metric" : "Imperial"));

                byte value = (byte)(isChecked ?
                        Constants.SPORTS_UNITS_METRIC : Constants.SPORTS_UNITS_IMPERIAL);

                // Update watchapp
                PebbleDictionary out = new PebbleDictionary();
                out.addUint8(Constants.SPORTS_UNITS_KEY, value);
                PebbleKit.sendDataToPebble(getApplicationContext(), Constants.SPORTS_UUID, out);
            }

        });

        final Switch sportsPace = (Switch)findViewById(R.id.switch_sports_pace);
        sportsPace.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {

            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                // Switch units
                sportsPace.setText("Pace or Speed: " + (isChecked ? "Speed" : "Pace"));

                byte value = (byte)(isChecked ?
                        Constants.SPORTS_DATA_SPEED : Constants.SPORTS_DATA_PACE);

                // Update watchapp
                PebbleDictionary out = new PebbleDictionary();
                out.addUint8(Constants.SPORTS_LABEL_KEY, value);
                PebbleKit.sendDataToPebble(getApplicationContext(), Constants.SPORTS_UUID, out);
            }

        });

        // Add Configure Golf button listeners
        final Button golfDummyData = (Button)findViewById(R.id.dummy_data_golf);
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
