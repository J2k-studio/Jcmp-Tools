package com.j2k.gamerun;

import android.app.Activity;
import android.content.res.AssetManager;
import android.opengl.GLSurfaceView;
import android.os.Build;
import android.os.Bundle;
import android.text.InputType;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.inputmethod.BaseInputConnection;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.InputMethodManager;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

/**
 * The window of a game that draws with OpenGL ES itself (makej apk with render = "gl"). The game is a shared library of J2K (libgame.so) that
 * the library glapp connects to this class: GameLib.init / resize / frame / touch. The GL thread calls the game; the touches are sent to it
 * on the same thread. Java 7.
 */
public class GlGameActivity extends Activity {
    private GLSurfaceView view;
    private boolean ready;

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN | WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        unpackAssets();
        view = new GLSurfaceView(this) {
            // the view takes text: the soft keyboard sends the characters here and they go to the game (GameLib.key)
            @Override
            public boolean onCheckIsTextEditor() { return true; }

            @Override
            public InputConnection onCreateInputConnection(EditorInfo out) {
                out.inputType = InputType.TYPE_CLASS_TEXT;
                out.imeOptions = EditorInfo.IME_FLAG_NO_FULLSCREEN | EditorInfo.IME_FLAG_NO_EXTRACT_UI;
                return new BaseInputConnection(this, false) {
                    @Override
                    public boolean commitText(CharSequence text, int newCursorPosition) {
                        for (int i = 0; i < text.length(); i++) { sendKey(text.charAt(i)); }
                        return true;
                    }

                    @Override
                    public boolean deleteSurroundingText(int before, int after) {
                        for (int i = 0; i < before; i++) { sendKey(8); }
                        return true;
                    }

                    @Override
                    public boolean sendKeyEvent(KeyEvent e) {
                        if (e.getAction() == KeyEvent.ACTION_DOWN) { keyDown(e); }
                        return true;
                    }
                };
            }
        };
        view.setFocusable(true);
        view.setFocusableInTouchMode(true);
        view.setEGLContextClientVersion(3);
        view.setEGLConfigChooser(8, 8, 8, 8, 0, 0);
        view.setRenderer(new GLSurfaceView.Renderer() {
            private long last;
            private int w, h;
            private boolean started;

            @Override
            public void onSurfaceCreated(GL10 gl, EGLConfig config) {
                started = false;
                last = System.nanoTime();
            }

            @Override
            public void onSurfaceChanged(GL10 gl, int width, int height) {
                w = width;
                h = height;
                if (!started) {
                    ready = GameLib.init(w, h) == 1;
                    started = true;
                } else if (ready) {
                    GameLib.resize(w, h);
                }
            }

            @Override
            public void onDrawFrame(GL10 gl) {
                long now = System.nanoTime();
                int ms = (int) ((now - last) / 1000000L);
                last = now;
                if (ready) {
                    GameLib.frame(ms);
                    pollKeyboard();
                }
            }
        });
        view.setRenderMode(GLSurfaceView.RENDERMODE_CONTINUOUSLY);
        setContentView(view);
        hideBars();
    }

    /** The files of assets/ of the project (they are in assets/data/ of the apk) are copied to files/data/ when the version of the app changes,
     *  and the game finds them by the environment variable JC_ASSETS (the same name that jcmp's libraries use); HOME is the folder files/ for saves. */
    private void unpackAssets() {
        try {
            File files = getFilesDir();
            File dir = new File(files, "data");
            File mark = new File(files, "data.version");
            String now = String.valueOf(getPackageManager().getPackageInfo(getPackageName(), 0).versionCode);
            boolean fresh = false;
            if (mark.exists()) {
                java.io.BufferedReader r = new java.io.BufferedReader(new java.io.FileReader(mark));
                try { fresh = now.equals(r.readLine()); } finally { r.close(); }
            }
            if (!fresh) {
                copyAssets("data", dir);
                FileOutputStream m = new FileOutputStream(mark);
                try { m.write(now.getBytes()); } finally { m.close(); }
            }
            android.system.Os.setenv("JC_ASSETS", dir.getPath(), true);
            android.system.Os.setenv("HOME", files.getPath(), true);
        } catch (Exception e) {
            // a game without files goes on
        }
    }

    private void copyAssets(String path, File to) throws IOException {
        AssetManager am = getAssets();
        String[] list = am.list(path);
        if (list != null && list.length > 0) {
            to.mkdirs();
            for (int i = 0; i < list.length; i++) { copyAssets(path + "/" + list[i], new File(to, list[i])); }
            return;
        }
        InputStream in = am.open(path);
        try {
            File dir = to.getParentFile();
            if (dir != null) { dir.mkdirs(); }
            OutputStream out = new FileOutputStream(to);
            try {
                byte[] buf = new byte[16384];
                int n;
                while ((n = in.read(buf)) > 0) { out.write(buf, 0, n); }
            } finally { out.close(); }
        } finally { in.close(); }
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

    @Override
    protected void onPause() {
        super.onPause();
        view.onPause();
    }

    @Override
    protected void onResume() {
        super.onResume();
        view.onResume();
    }

    // touches go to the game on the GL thread: 1 down, 2 move, 3 up (the same numbers as in the Jaric app)
    @Override
    public boolean onTouchEvent(MotionEvent e) {
        final int masked = e.getActionMasked();
        final int index = e.getActionIndex();
        if (masked == MotionEvent.ACTION_MOVE) {
            for (int i = 0; i < e.getPointerCount(); i++) {
                send(2, (int) e.getX(i), (int) e.getY(i), e.getPointerId(i));
            }
        } else if (masked == MotionEvent.ACTION_DOWN || masked == MotionEvent.ACTION_POINTER_DOWN) {
            send(1, (int) e.getX(index), (int) e.getY(index), e.getPointerId(index));
        } else if (masked == MotionEvent.ACTION_UP || masked == MotionEvent.ACTION_POINTER_UP || masked == MotionEvent.ACTION_CANCEL) {
            send(3, (int) e.getX(index), (int) e.getY(index), e.getPointerId(index));
        }
        return true;
    }

    private void send(final int action, final int x, final int y, final int id) {
        view.queueEvent(new Runnable() {
            @Override
            public void run() {
                if (ready) { GameLib.touch(action, x, y, id); }
            }
        });
    }

    private int keyboardShown;
    private boolean keyboardBroken;

    // the game says every frame whether it wants the soft keyboard; the keyboard is shown or hidden on the screen thread when that changes
    private void pollKeyboard() {
        if (keyboardBroken) { return; }
        int want;
        try {
            want = GameLib.wantsKeyboard();
        } catch (UnsatisfiedLinkError e) {
            keyboardBroken = true;                     // a game built with an older glapp: no keyboard
            return;
        }
        if (want != keyboardShown) {
            keyboardShown = want;
            final boolean show = want == 1;
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    InputMethodManager imm = (InputMethodManager) getSystemService(INPUT_METHOD_SERVICE);
                    if (imm == null) { return; }
                    if (show) {
                        view.requestFocus();
                        imm.showSoftInput(view, 0);
                    } else {
                        imm.hideSoftInputFromWindow(view.getWindowToken(), 0);
                    }
                }
            });
        }
    }

    // a character to the game on the GL thread
    private void sendKey(final int ch) {
        view.queueEvent(new Runnable() {
            @Override
            public void run() {
                if (ready && !keyboardBroken) {
                    try { GameLib.key(ch); } catch (UnsatisfiedLinkError e) { keyboardBroken = true; }
                }
            }
        });
    }

    // a key of a hardware keyboard, or one the soft keyboard sends as a key: letters and digits by their character, delete = 8, enter = 10
    private void keyDown(KeyEvent e) {
        int code = e.getKeyCode();
        if (code == KeyEvent.KEYCODE_DEL) { sendKey(8); return; }
        if (code == KeyEvent.KEYCODE_ENTER) { sendKey(10); return; }
        int u = e.getUnicodeChar();
        if (u > 0) { sendKey(u); }
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent e) {
        if (keyCode == KeyEvent.KEYCODE_BACK) { return super.onKeyDown(keyCode, e); }
        keyDown(e);
        return true;
    }
}
