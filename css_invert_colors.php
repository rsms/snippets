<?

$infile = 'hunchblog0808271746-hong-kong_files/screen_org.css';
$outfile = 'hunchblog0808271746-hong-kong_files/screen.css';

$css = file_get_contents($infile);

function col_invert($s) {
  $short = false;
  if (strlen($s) < 6) {
    $s = $s{0}.$s{0}.$s{1}.$s{1}.$s{2}.$s{2};
    $short = true;
  }
  $s = sprintf('%x', 0xffffff - intval($s,16));
  if ($short)
    return $s{0}.$s{2}.$s{4};
  return $s;
}

$css = preg_replace('/#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})/e', '"#".col_invert("$1");', $css);
#print_r($m);
file_put_contents($outfile, $css);


$a = '73949f';
$a = '799';
#echo col_invert($a);
$b = '8c6b60';

?>