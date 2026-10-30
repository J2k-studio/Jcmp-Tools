# ask

Find the answer in your own documents. No model, no network: a search (BM25) over the `.md`, `.txt` and `.jk` files of some folders, in English and Thai.

    ask how do I open a file
    ask -n 5 -d ~/notes thread
    ASK_DIRS=~/a:~/b ask square root

Without `-d` or `ASK_DIRS` it reads `~/Jcmp/docs`, `~/Jcmp-libs/docs`, `lessons` and `examples`. It shows the best passages (3 by default) with the file name and the score. When nothing matches it says so and exits with 1.

This is the first step (A0) of the assistant of Jaric: the answer that a trained model will later write is checked against these passages.
