package com.j2k.gamerun;

import android.app.Activity;
import android.opengl.GLSurfaceView;
import android.os.Build;
import android.os.Bundle;
import android.view.MotionEvent;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;

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
        view = new GLSurfaceView(this);
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
                if (ready) { GameLib.frame(ms); }
            }
        });
        view.setRenderMode(GLSurfaceView.RENDERMODE_CONTINUOUSLY);
        setContentView(view);
        hideBars();
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
}
