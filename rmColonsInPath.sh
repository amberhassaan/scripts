for i in $* ; do 
  x=$(echo $i|sed 's/:/-/g'); 
  echo "moving $i TO $x"; 
  mv $i $x;
done
