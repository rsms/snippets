<?
function list_extend(array &$dst, array &$src) {
  $len = count($src);
  for($i=0;$i<$len;$i++)
    $dst[] =& $src[$i];
}
?>