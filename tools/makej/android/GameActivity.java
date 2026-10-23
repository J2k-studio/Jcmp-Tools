package com.j2k.gamerun;

import android.app.Activity;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.media.MediaPlayer;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.FrameLayout;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Map;

/**
 * The runner of a game made with makej (makej apk). The game is a program of J2K (assets/bin/game) that talks the protocol of the Jaric app:
 * it draws pictures of pixels (ESC ] 7777 ; gfx ; ...), plays sounds (audio) and reads touches and keys. This activity starts it through
 * jpty (a pseudo terminal), draws its pictures on a surface with the graphics chip and sends the touches and the keys back. Java 7.
 */
public class GameActivity extends Activity {
    private SurfaceView sv;
    private Overlay overlay;
    private OutputStream toGame;
    private Process proc;
    private volatile boolean running = true;
    private final Handler ui = new Handler();

    // the picture
    private int gw, gh;
    private RandomAccessFile fb;
    private Bitmap bmp;
    private int[] pix;
    private byte[] bytes;
    private final Paint sharp = new Paint();

    // the sound
    private MediaPlayer player;
    private float vol = 1f;

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN | WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        sharp.setFilterBitmap(false);
        FrameLayout root = new FrameLayout(this);
        root.setBackgroundColor(Color.BLACK);
        sv = new SurfaceView(this);
        root.addView(sv, new FrameLayout.LayoutParams(-1, -1));
        boolean controls = true;
        try {
            ApplicationInfo ai = getPackageManager().getApplicationInfo(getPackageName(), PackageManager.GET_META_DATA);
            if (ai.metaData != null) { controls = ai.metaData.getBoolean("controls", true); }
        } catch (PackageManager.NameNotFoundException e) {
            // the default
        }
        overlay = new Overlay(this, controls);
        root.addView(overlay, new FrameLayout.LayoutParams(-1, -1));
        setContentView(root);
        hideBars();
        new Thread(new Runnable() {
            @Override
            public void run() {
                if (install()) { startGame(); } else { ui.post(new Runnable() { public void run() { finish(); } }); }
            }
        }).start();
    }

    private void hideBars() {
        if (Build.VERSION.SDK_INT >= 19) {
            getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
        }
    }

    @Override
    public void onWindowFocusChanged(boolean f) {
        super.onWindowFocusChanged(f);
        if (f) { hideBars(); }
    }

    // ---------------------------------------------------------------- the files: the game and jpty out of the APK, the data of the game
    private boolean install() {
        try {
            File files = getFilesDir();
            File bin = new File(files, "bin");
            bin.mkdirs();
            String[] names = {"game", "jpty"};
            for (int i = 0; i < names.length; i++) {
                copyAsset("bin/" + names[i], new File(bin, names[i]));
                new File(bin, names[i]).setExecutable(true, false);
            }
            copyTree("data", new File(files, "data"));
            return true;
        } catch (IOException e) {
            return false;
        }
    }

    private void copyAsset(String name, File to) throws IOException {
        InputStream in = getAssets().open(name);
        FileOutputStream out = new FileOutputStream(to);
        byte[] buf = new byte[16384];
        int n;
        while ((n = in.read(buf)) > 0) { out.write(buf, 0, n); }
        out.close();
        in.close();
    }

    private void copyTree(String asset, File to) throws IOException {
        AssetManager am = getAssets();
        String[] list = am.list(asset);
        if (list == null) { return; }
        if (list.length == 0) {
            to.getParentFile().mkdirs();
            copyAsset(asset, to);
            return;
        }
        to.mkdirs();
        for (int i = 0; i < list.length; i++) { copyTree(asset + "/" + list[i], new File(to, list[i])); }
    }

    // ---------------------------------------------------------------- the game process
    private void startGame() {
        try {
            File files = getFilesDir();
            ProcessBuilder pb = new ProcessBuilder(new File(files, "bin/jpty").getPath(), "-w", "80", "-h", "24", new File(files, "bin/game").getPath());
            pb.directory(files);
            pb.redirectErrorStream(true);
            Map<String, String> env = pb.environment();
            env.put("HOME", files.getPath());
            env.put("TMPDIR", getCacheDir().getPath());
            env.put("TERM", "xterm-256color");
            env.put("LANG", "en_US.UTF-8");
            env.put("JARIC", "1");
            env.put("JEC_ASSETS", new File(files, "data").getPath());
            proc = pb.start();
            toGame = proc.getOutputStream();
            InputStreamReader r = new InputStreamReader(proc.getInputStream(), "UTF-8");
            char[] buf = new char[4096];
            StringBuilder acc = new StringBuilder();
            int n;
            while (running && (n = r.read(buf)) > 0) {
                acc.append(buf, 0, n);
                int at;
                while ((at = acc.indexOf("\u001b]7777;")) >= 0) {
                    int end = acc.indexOf("\u0007", at);
                    if (end < 0) { break; }
                    handle(acc.substring(at + 7, end));
                    acc.delete(0, end + 1);
                }
                if (acc.length() > 65536) { acc.setLength(0); }              // text that is not for us
            }
        } catch (IOException e) {
            // the game ended
        }
        running = false;
        ui.post(new Runnable() { public void run() { finish(); } });
    }

    private void send(String s) {
        try {
            if (toGame != null) { toGame.write(s.getBytes("UTF-8")); toGame.flush(); }
        } catch (IOException e) {
            // the game ended
        }
    }

    private void handle(String cmd) {
        try {
            if (cmd.startsWith("gfx;open;")) {
                String[] p = cmd.split(";", 5);
                gw = Integer.parseInt(p[2]);
                gh = Integer.parseInt(p[3]);
                fb = new RandomAccessFile(p[4], "r");
                bmp = Bitmap.createBitmap(gw, gh, Bitmap.Config.ARGB_8888);
                pix = new int[gw * gh];
                bytes = new byte[gw * gh * 4];
                overlay.setPicture(gw, gh);
            } else if (cmd.equals("gfx;present")) {
                present();
            } else if (cmd.equals("gfx;close")) {
                running = false;
            } else if (cmd.startsWith("audio;")) {
                audio(cmd.substring(6));
            }
        } catch (Exception e) {
            send("\u001b]7777;gfx-error;" + String.valueOf(e.getMessage()).replace(';', ',') + "\u0007");
        }
    }

    private void present() throws IOException {
        SurfaceHolder holder = sv.getHolder();
        if (fb == null || holder.getSurface() == null || !holder.getSurface().isValid()) { return; }
        fb.seek(0);
        fb.readFully(bytes);
        ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN).asIntBuffer().get(pix);
        bmp.setPixels(pix, 0, gw, 0, 0, gw, gh);
        Canvas c = Build.VERSION.SDK_INT >= 26 ? holder.getSurface().lockHardwareCanvas() : holder.lockCanvas();
        if (c == null) { return; }
        c.drawColor(Color.BLACK);
        Rect dst = overlay.target(c.getWidth(), c.getHeight());
        c.drawBitmap(bmp, null, dst, sharp);
        holder.getSurface().unlockCanvasAndPost(c);
    }

    private void audio(String cmd) throws IOException {
        if (cmd.startsWith("play;")) {
            if (player != null) { player.release(); player = null; }
            String path = cmd.substring(5);
            File f = new File(path);
            if (!f.isAbsolute()) { f = new File(new File(getFilesDir(), "data"), path); }
            player = new MediaPlayer();
            player.setDataSource(f.getPath());
            player.prepare();
            player.setVolume(vol, vol);
            player.start();
        } else if (cmd.equals("pause") && player != null) {
            player.pause();
        } else if (cmd.equals("resume") && player != null) {
            player.start();
        } else if (cmd.equals("stop") && player != null) {
            player.release();
            player = null;
        } else if (cmd.startsWith("volume;")) {
            vol = Math.max(0, Math.min(100, Integer.parseInt(cmd.substring(7).trim()))) / 100f;
            if (player != null) { player.setVolume(vol, vol); }
        }
    }

    // ---------------------------------------------------------------- keys
    @Override
    public boolean onKeyDown(int code, KeyEvent e) {
        if (code == KeyEvent.KEYCODE_BACK) { quit(); return true; }
        String k = null;
        if (code == KeyEvent.KEYCODE_DPAD_UP) { k = "\u001b[A"; }
        else if (code == KeyEvent.KEYCODE_DPAD_DOWN) { k = "\u001b[B"; }
        else if (code == KeyEvent.KEYCODE_DPAD_RIGHT) { k = "\u001b[C"; }
        else if (code == KeyEvent.KEYCODE_DPAD_LEFT) { k = "\u001b[D"; }
        else if (code == KeyEvent.KEYCODE_ENTER) { k = "\r"; }
        else if (code == KeyEvent.KEYCODE_SPACE) { k = " "; }
        else if (code == KeyEvent.KEYCODE_ESCAPE) { k = "\u001b"; }
        else {
            int u = e.getUnicodeChar();
            if (u > 0) { k = new String(Character.toChars(u)); }
        }
        if (k != null) { send(k); return true; }
        return super.onKeyDown(code, e);
    }

    private void quit() {
        running = false;
        if (proc != null) { proc.destroy(); }
        finish();
    }

    @Override
    protected void onDestroy() {
        running = false;
        if (proc != null) { proc.destroy(); }
        if (player != null) { player.release(); player = null; }
        super.onDestroy();
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (player != null && player.isPlaying()) { player.pause(); }
    }

    // ---------------------------------------------------------------- the touches and the buttons on the picture
    private class Overlay extends View {
        private final boolean controls;
        private final Paint pt = new Paint();
        private int pw = 1, ph = 1;
        private final int[] bx = new int[6];            // left right up down A B : the centres
        private final int[] by = new int[6];
        private final String[] keys = {"\u001b[D", "\u001b[C", "\u001b[A", "\u001b[B", " ", "\r"};
        private final String[] label = {"<", ">", "^", "v", "A", "B"};
        private final boolean[] down = new boolean[6];
        private final int[] holdId = new int[6];
        private int radius;

        Overlay(android.content.Context c, boolean controls) {
            super(c);
            this.controls = controls;
            pt.setAntiAlias(true);
            pt.setTextAlign(Paint.Align.CENTER);
            ui.postDelayed(repeat, 50);
        }

        void setPicture(int w, int h) { pw = w; ph = h; }

        Rect target(int w, int h) {
            float scale = Math.min((float) w / pw, (float) h / ph);
            int dw = (int) (pw * scale);
            int dh = (int) (ph * scale);
            int dx = (w - dw) / 2;
            int dy = (h - dh) / 2;
            return new Rect(dx, dy, dx + dw, dy + dh);
        }

        private void layout(int w, int h) {
            radius = Math.min(w, h) / 9;
            int m = radius + radius / 2;
            bx[0] = m; by[0] = h - m * 2;
            bx[1] = m * 3; by[1] = h - m * 2;
            bx[2] = m * 2; by[2] = h - m * 3;
            bx[3] = m * 2; by[3] = h - m;
            bx[4] = w - m * 3; by[4] = h - m * 2;
            bx[5] = w - m; by[5] = h - m * 2;
        }

        @Override
        protected void onDraw(Canvas c) {
            if (!controls) { return; }
            layout(getWidth(), getHeight());
            pt.setTextSize(radius);
            for (int i = 0; i < 6; i++) {
                pt.setColor(down[i] ? 0x66FFFFFF : 0x33FFFFFF);
                c.drawCircle(bx[i], by[i], radius, pt);
                pt.setColor(0xAAFFFFFF);
                c.drawText(label[i], bx[i], by[i] + radius / 3, pt);
            }
        }

        private final Runnable repeat = new Runnable() {
            @Override
            public void run() {
                for (int i = 0; i < 6; i++) { if (down[i]) { send(keys[i]); } }
                if (running) { ui.postDelayed(this, 50); }
            }
        };

        private int buttonAt(float x, float y) {
            if (!controls) { return -1; }
            for (int i = 0; i < 6; i++) {
                float dx = x - bx[i];
                float dy = y - by[i];
                if (dx * dx + dy * dy <= radius * radius * 1.6f) { return i; }
            }
            return -1;
        }

        @Override
        public boolean onTouchEvent(MotionEvent e) {
            layout(getWidth(), getHeight());
            int a = e.getActionMasked();
            boolean up = a == MotionEvent.ACTION_UP || a == MotionEvent.ACTION_POINTER_UP || a == MotionEvent.ACTION_CANCEL;
            Rect t = target(getWidth(), getHeight());
            float scale = (float) t.width() / pw;
            if (a == MotionEvent.ACTION_CANCEL) { for (int i = 0; i < 6; i++) { down[i] = false; } }
            for (int i = 0; i < e.getPointerCount(); i++) {
                boolean mine = i == e.getActionIndex() || a == MotionEvent.ACTION_MOVE;
                if (!mine) { continue; }
                int id = e.getPointerId(i);
                float x = e.getX(i);
                float y = e.getY(i);
                int b = buttonAt(x, y);
                if (b >= 0 && !up) {
                    if (!down[b]) { send(keys[b]); }
                    down[b] = true;
                    holdId[b] = id;
                    continue;
                }
                if (up) { for (int k = 0; k < 6; k++) { if (down[k] && holdId[k] == id) { down[k] = false; } } }
                if (b >= 0) { continue; }
                int px = (int) ((x - t.left) / scale);
                int py = (int) ((y - t.top) / scale);
                String st = up ? "U" : (a == MotionEvent.ACTION_MOVE ? "M" : "D");
                send("\u001b]7777;touch;" + st + ";" + px + ";" + py + ";" + id + "\u0007");
            }
            if (a == MotionEvent.ACTION_MOVE) {                            // a finger that slid off a button lets it go
                for (int k = 0; k < 6; k++) {
                    if (!down[k]) { continue; }
                    boolean still = false;
                    for (int i = 0; i < e.getPointerCount(); i++) { if (e.getPointerId(i) == holdId[k] && buttonAt(e.getX(i), e.getY(i)) == k) { still = true; } }
                    if (!still) { down[k] = false; }
                }
            }
            invalidate();
            return true;
        }
    }
}
