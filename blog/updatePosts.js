var fs = require('fs');
var marked = require('marked');

//Get a list of all markdown files in this directory
var markdownFiles = fs.readdirSync('./posts/').filter(function(file){ return (file.indexOf('.md') != -1); });

//Set up the CSS and javascript to put at the top of each generated HTML page
var htmlIncludes = '<link rel="stylesheet" type="text/css" href="../postStyle.css">\n<link rel="stylesheet" href="../highlight/styles/default.css">\n<script src="../highlight/highlight.pack.js"></script>\n<script>hljs.initHighlightingOnLoad();</script>\n';

//Convert each markdown file to HTML, save it, and add its filename to the list of posts
var postList = []
markdownFiles.forEach(function(mdFileName) {
	var mdFile = fs.readFileSync('./posts/' + mdFileName, 'utf8');
	var htmlFile = htmlIncludes.concat(marked(mdFile));
	var htmlFileName = mdFileName.replace('.md', '.html');
	fs.writeFileSync('./posts/' + htmlFileName, htmlFile);
	postList.push(htmlFileName);
	console.log('Converted file: ' + mdFileName);
});

//Save the list of post HTML files to a JSON file
fs.writeFileSync('./posts/postList.json', JSON.stringify(postList));

console.log('Done converting!');