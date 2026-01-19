package com.hive.status;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.Typeface;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class MainActivity extends Activity {

    private TextView statusIndicator;
    private TextView statusText;
    private TextView toTTime;
    private TextView toZTime;

    private static final String SYNC_DIR = "/storage/emulated/0/claude-sync/";
    private static final long STALE_THRESHOLD = 5 * 60 * 1000;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setGravity(Gravity.CENTER_HORIZONTAL);
        root.setPadding(60, 60, 60, 60);
        root.setBackgroundColor(Color.parseColor("#1a1a2e"));

        // Title
        TextView title = new TextView(this);
        title.setText("THE HIVE");
        title.setTextSize(32);
        title.setTextColor(Color.parseColor("#00d4ff"));
        title.setTypeface(null, Typeface.BOLD);
        title.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT);
        titleParams.bottomMargin = 80;
        root.addView(title, titleParams);

        // Status indicator
        statusIndicator = new TextView(this);
        statusIndicator.setText("?");
        statusIndicator.setTextSize(48);
        statusIndicator.setTextColor(Color.WHITE);
        statusIndicator.setGravity(Gravity.CENTER);
        statusIndicator.setBackgroundColor(Color.parseColor("#F59E0B"));
        LinearLayout.LayoutParams indParams = new LinearLayout.LayoutParams(300, 300);
        indParams.bottomMargin = 60;
        root.addView(statusIndicator, indParams);

        // Status text
        statusText = new TextView(this);
        statusText.setText("Checking...");
        statusText.setTextSize(18);
        statusText.setTextColor(Color.parseColor("#888888"));
        statusText.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams stParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT);
        stParams.bottomMargin = 80;
        root.addView(statusText, stParams);

        // to-t.md label
        TextView toTLabel = new TextView(this);
        toTLabel.setText("to-t.md (Z's outbox)");
        toTLabel.setTextSize(14);
        toTLabel.setTextColor(Color.parseColor("#00d4ff"));
        root.addView(toTLabel);

        // to-t.md time
        toTTime = new TextView(this);
        toTTime.setText("--");
        toTTime.setTextSize(16);
        toTTime.setTextColor(Color.WHITE);
        LinearLayout.LayoutParams ttParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT);
        ttParams.bottomMargin = 40;
        root.addView(toTTime, ttParams);

        // to-z.md label
        TextView toZLabel = new TextView(this);
        toZLabel.setText("to-z.md (T's outbox)");
        toZLabel.setTextSize(14);
        toZLabel.setTextColor(Color.parseColor("#7c3aed"));
        root.addView(toZLabel);

        // to-z.md time
        toZTime = new TextView(this);
        toZTime.setText("--");
        toZTime.setTextSize(16);
        toZTime.setTextColor(Color.WHITE);
        LinearLayout.LayoutParams tzParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT);
        tzParams.bottomMargin = 80;
        root.addView(toZTime, tzParams);

        // Refresh button
        Button refreshBtn = new Button(this);
        refreshBtn.setText("REFRESH");
        refreshBtn.setBackgroundColor(Color.parseColor("#7c3aed"));
        refreshBtn.setTextColor(Color.WHITE);
        refreshBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                checkStatus();
            }
        });
        root.addView(refreshBtn);

        setContentView(root);
        checkStatus();
    }

    private void checkStatus() {
        File toT = new File(SYNC_DIR + "to-t.md");
        File toZ = new File(SYNC_DIR + "to-z.md");

        long toTMod = toT.exists() ? toT.lastModified() : 0;
        long toZMod = toZ.exists() ? toZ.lastModified() : 0;
        long now = System.currentTimeMillis();

        SimpleDateFormat sdf = new SimpleDateFormat("MMM dd HH:mm:ss", Locale.US);

        toTTime.setText(toTMod > 0 ? sdf.format(new Date(toTMod)) : "Not found");
        toZTime.setText(toZMod > 0 ? sdf.format(new Date(toZMod)) : "Not found");

        long newest = Math.max(toTMod, toZMod);
        long age = now - newest;

        if (newest == 0) {
            statusIndicator.setText("!");
            statusIndicator.setBackgroundColor(Color.parseColor("#EF4444"));
            statusText.setText("Files not found");
        } else if (age < STALE_THRESHOLD) {
            statusIndicator.setText("OK");
            statusIndicator.setBackgroundColor(Color.parseColor("#10B981"));
            statusText.setText("Active - " + (age / 1000) + "s ago");
        } else {
            statusIndicator.setText("?");
            statusIndicator.setBackgroundColor(Color.parseColor("#F59E0B"));
            statusText.setText("Stale - " + (age / 60000) + "m ago");
        }
    }
}
