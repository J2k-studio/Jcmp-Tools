x=hello.txt
echo ${x%.txt} ${#x} ${x:1:3} ${y:-dflt} ${x/l/L} ${x//l/L} ${x#he} ${x##*l} ${x%%.*} ${x:-no}
f=/a/b/c.tar.gz
echo ${f##*/} ${f%/*} ${f%%.*}
echo ${y:=set} $y ${y:+yes}
