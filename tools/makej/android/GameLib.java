package com.j2k.gamerun;

/** The game of J2K (a shared library, libgame.so) as the app sees it. The names are the JNI entry points of the library glapp of J2K. */
public class GameLib {
    static { System.loadLibrary("game"); }
    public static native int init(int w, int h);
    public static native void resize(int w, int h);
    public static native void frame(int ms);
    public static native void touch(int action, int x, int y, int id);
}
