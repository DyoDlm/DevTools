a="aa a  a aa a  aa aa"
#echo "${a/aa/aaa}"

s="-rw-rw-r-- 1 leenovox leenovox 5615397 avril 12 09:59 '17. Interférences & Fentes de Young (Terminale spécialité Physique Chimie) [Lx-KeSSKQOg].mp3'-rw-rw-r-- 1 leenovox leenovox 5615397 avril 12 09:59 '17. Interférences & Fentes de Young (Terminale spécialité Physique Chimie) [Lx-KeSSKQOg].mp3'-rw-rw-r-- 1 leenovox leenovox 5615397 avril 12 09:59 '17. Interférences & Fentes de Young (Terminale spécialité Physique Chimie) [Lx-KeSSKQOg].mp3'"


s="${s//[a-z]/ }"
s="${s//[A-Z]/ }"


#echo $s

a=3
b=0
((b+=a))
echo $b

