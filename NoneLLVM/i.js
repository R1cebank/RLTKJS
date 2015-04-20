<script type="text/JavaScript">
function fib(a) {
	if (a == 0 || a == 1) {
		return a;
	}
	return fib(a - 1) + fib(a - 2);
}

var x = 0;
while (x <= 20) {
	document.write(fib(x), "<br />");
	x = x + 1;
}
</script>
