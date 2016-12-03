<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" omit-xml-declaration="yes" indent="no"/>

  <xsl:template match="//syntax">
<![CDATA[
// Generated From parse_gen. http://www.github.com/mikey-b/parser_gen/ 

function isEmpty(map) {
	for(var key in map) {
		if (map.hasOwnProperty(key)) return false;
	}
	return true;
}

class SyntaxNode {
	constructor() {
		this.childNodes = [];
		this.index = {};
		this.length = 0;
		this.attributes = {};
	}

	addAttribute(value, key) {
		this.attributes[key] = value;
	}
	
	getAttribute(key) {
		return this.attributes[key];	
	}

	addIndexedNode(node, indexName) {
		this.childNodes.push(node);
		if (this.index[indexName] === undefined) this.index[indexName] = [];
		this.index[indexName].push( this.childNodes.length - 1 );
		this.length += node.length;
	}

	getNodes(indexName) {
		var res = [];
		for(let i in this.index[indexName]) {
			res.push(this.childNodes[this.index[indexName][i]]);
		}
		return res;
	}

	getValue(indexName) {
		return this.childNodes[this.index[indexName][0]].text();
	}
	
	addNode(node) {
		this.childNodes.push(node);
		this.length += node.length;
	}

	text() {
		var res = '';
		for(let child of this.childNodes) {
			res += child.text();
		}
		return res;
	}

	toXML(role, depth) {
		role = role || "root";
		depth = depth || 0;

		var res = "\t".repeat(depth) + '<' + role;
		for (var a in this.attributes) {
			res += ' ' + a + '="' + this.attributes[a] + '"';
		}
		if (isEmpty(this.index)) {
			res += '/>';
		} else {
			res += '>\n';

			for(var c in this.index) {
				for(var d in this.index[c]) {
					res += this.childNodes[this.index[c][d]].toXML(c, depth+1) + '\n';
				}
			}
			res += "\t".repeat(depth) + '</' + role + '>';
		}
		
		return res;
		
	}
	toHTML() {
		var thisClassName = this.constructor.name;
		var res = '<span class="' + thisClassName + '">';

		for(var i = 0, len = this.childNodes.length; i < len; i++) {
			res += this.childNodes[i].toHTML();
		}
		res += '</span>';
		return res;
	}
}

// Lexing Nodes
// We need to add methods to the created Objects (Parse tree).
// We do this with inheritence. Create a variable with the name of the token match name
// to add methods to those token types.

class LexNode {
	constructor() {
		this.value = undefined;
		this.length = 0;
		this.attributes = {};
	}
	
	toHTML() {
		var thisClassName = this.constructor.name;
		return "<span class='" + thisClassName + "'>" + this.text() + "</span>";
	}
	
	text() {
		// EOF represented with \n with length 0
		if (this.length != 0) return this.value;
		return '';
	}

	addAttribute(value,key) {
		this.attributes[key] = value;
	}	

	getAttribute(key) {
		return this.attributes[key];
	}

	toXML(role, depth) {
		var res;
		res = "\t".repeat(depth) + '<' + role;
		for (var a in this.attributes) {
			res += ' ' + a + '="' + this.attributes[a] + '"';
		}
		res += '>' + this.text() + '</' + role + '>';
		return res;
	}
};

// Lexical Nodes, whitespace, selector, identifier, number.

class commentString extends LexNode {
	constructor(inputstream) {
		super();

		var re = new RegExp("^[^\n]*");
		var res = re.exec(inputstream);
		
		if (res === null) throw "Expected comment string";
		
		this.length = res[0].length;
		this.value = res[0];
	}
}
]]>
<xsl:apply-templates/>
</xsl:template>

<xsl:template match="lex">
  const <xsl:value-of select="name"/>_re = new RegExp("^<xsl:value-of select="."/>");
  class <xsl:value-of select="name"/> extends LexNode {
	  constructor(inputstream) {
  		super();
	  	var res = <xsl:value-of select="name"/>_re.exec(inputstream);
		
		  if (res === null) throw "Expected whitespace";
		
		  this.length = res[0].length;
		  this.value = res[0];
	  }
  }
</xsl:template>

<xsl:template match="statement">
	class <xsl:value-of select="@name"/> extends SyntaxNode {
		constructor(inputstream) {
			super();
			var tmp;

			<xsl:apply-templates/>
		}
	};
</xsl:template>

<xsl:template match="match">
	<xsl:if test="@optional='true'">try { // optional</xsl:if>
	tmp = new <xsl:value-of select="@statement"/>(inputstream);
	<xsl:if test="name(..) ='one-of'">tmp.addAttribute('<xsl:value-of select="@statement"/>', 'type');</xsl:if>
	<xsl:choose>
		<xsl:when test="(name(..) = 'one-of') and ../@index">super.addIndexedNode(tmp, '<xsl:value-of select="../@index"/>');</xsl:when>
		<xsl:when test="@index">super.addIndexedNode(tmp, '<xsl:value-of select="@index"/>');</xsl:when>
		<xsl:otherwise>super.addNode(tmp);</xsl:otherwise>
	</xsl:choose>
	inputstream = inputstream.substr(tmp.length);
	<xsl:if test="@optional='true'">} catch(e) { }</xsl:if>
</xsl:template>

<xsl:template match="one-or-more">
	var one_or_more_count = 0;
	try {
		while(inputstream != '') {
			<xsl:apply-templates/>

			one_or_more_count += 1;

			<xsl:if test="@delimiter">
			<xsl:call-template name="implicitRemoveWhiteSpace"/>
			// If we fail, end the loop.
			tmp = new sign(inputstream);
			if (tmp.value != '<xsl:value-of select='@delimiter'/>') { throw "Not delimiter"; }
			super.addNode(tmp);
			inputstream = inputstream.substr(tmp.length);
			<xsl:call-template name="implicitRemoveWhiteSpace"/>
			</xsl:if>
		}
	} catch(e) {<xsl:if test="not(@optional)">if (one_or_more_count === 0) throw "One-or-more failed, " + e;</xsl:if>}
</xsl:template>

<xsl:template match="one-of">
	<xsl:for-each select="child::*">
		try {
			<xsl:apply-templates select="."/>
		} catch(e) {
	</xsl:for-each>
		<!-- The last nested level -->
		throw "<xsl:value-of select='../@name'/>: one-of didnt match";
	<xsl:for-each select="child::*">} </xsl:for-each>
</xsl:template>

<xsl:template match="eof">
	if (inputstream != '') throw "Expected EOF";
</xsl:template>

<!-- Lexing Functions -->
<xsl:template match="*[not(name()='statement') and not(name()='lex') and not(name()='syntax') and not(name()='one-of') and not(name()='one-or-more')]">
	<xsl:if test="@optional">try {</xsl:if>
	tmp = new <xsl:value-of select="name(.)"/>(inputstream);
	<xsl:if test=". != ''">if (tmp.value != '<xsl:value-of select="."/>') { throw "Expected '<xsl:value-of select="."/>' keyword"; }</xsl:if>
	<xsl:if test="name(..) ='one-of'">tmp.addAttribute('<xsl:value-of select="name(.)"/>', 'type');</xsl:if>
	<xsl:choose>
		<xsl:when test="(name(..) = 'one-or-more') and @index">super.addIndexedNode(tmp, '<xsl:value-of select="@index"/>');</xsl:when>
		<xsl:when test="(name(..) = 'one-of') and ../@index">super.addIndexedNode(tmp, '<xsl:value-of select="../@index"/>');</xsl:when>
		<xsl:when test="@index">
			super.addNode(tmp);
			super.addAttribute(tmp.value, '<xsl:value-of select="@index"/>');
		</xsl:when>
		<xsl:otherwise>super.addNode(tmp);</xsl:otherwise>
	</xsl:choose>
	inputstream = inputstream.substr(tmp.length);
	<xsl:if test="@optional">} catch(e) { }</xsl:if>
</xsl:template>

</xsl:stylesheet>
