<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
  xmlns="http://www.loc.gov/MARC21/slim" xmlns:mei="http://www.music-encoding.org/ns/mei"
  exclude-result-prefixes="mei">
  <xsl:output method="xml" encoding="UTF-8" indent="yes" media-type="text/xml"/>
  <xsl:strip-space elements="*"/>

  <!-- PARAM:mode
      This parameter determines which entity the generated MARC record is for:
        'file': the MEI file,
        'source': the source(s) of the MEI file,
        'work': the work the MEI file represents.
  -->
  <xsl:param name="mode">file</xsl:param>
  <xsl:param name="model_path"
    >http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd</xsl:param>

  <!-- version -->
  <xsl:variable name="version">
    <xsl:text>1.0 ALPHA</xsl:text>
  </xsl:variable>

  <xsl:template match="/">
    <xsl:apply-templates select="//mei:meiHead"/>
  </xsl:template>

  <xsl:template match="mei:meiHead">
    <xsl:if test="$model_path != ''">
      <xsl:processing-instruction name="xml-model">
        <xsl:value-of select="concat('&#32;href=&quot;', $model_path, '&quot;')"/>
      </xsl:processing-instruction>
    </xsl:if>
    <xsl:comment>
      <xsl:text>MARC record generated by mei2marc.xsl version </xsl:text>
      <xsl:value-of select="$version"/>
    </xsl:comment>
    <record>
      <xsl:choose>
        <xsl:when test="$mode = 'file'">
          <xsl:apply-templates select="mei:fileDesc"/>
        </xsl:when>
      </xsl:choose>
    </record>
  </xsl:template>

  <xsl:template name="leader">
    <xsl:variable name="leaderComment">The leader value is *bogus*, just here to get the output to
      validate!</xsl:variable>
    <xsl:comment>
      <xsl:value-of select="normalize-space($leaderComment)"/>
    </xsl:comment>
    <leader>01044ccm a2200301Ia 4500</leader>
  </xsl:template>

  <xsl:template name="controlField">
    <xsl:param name="tag"/>
    <xsl:param name="value"/>
    <controlfield tag="{$tag}">
      <xsl:value-of select="$value"/>
    </controlfield>
  </xsl:template>

  <xsl:template name="subfield">
    <xsl:param name="code"/>
    <xsl:param name="value"/>
    <xsl:param name="delimiter"/>
    <subfield code="{$code}">
      <xsl:value-of select="$value"/>
      <xsl:value-of select="$delimiter"/>
    </subfield>
  </xsl:template>

  <xsl:template match="mei:fileDesc">
    <!-- LEADER -->
    <xsl:call-template name="leader"/>

    <!-- CONTROL FIELDS -->
    <xsl:if test="../mei:altId">
      <xsl:apply-templates select="../mei:altId"/>
    </xsl:if>

    <!-- DATA FIELDS -->
    <!-- Call Number(s) -->
    <xsl:apply-templates select="//mei:classification//mei:term[contains(@analog, 'marc:090')]"/>

    <!-- Main Entry -->
    <xsl:apply-templates select="mei:titleStmt/mei:respStmt/mei:persName[contains(@analog,
      'marc:100') or       contains(@role, 'creator') or contains(@role, 'composer')]"/>

    <!-- Titles -->
    <!-- Uniform Title -->
    <xsl:choose>
      <xsl:when test="mei:titleStmt/mei:title[contains(@analog, 'marc:240') or contains(@type,
        'uniform')]">
        <xsl:apply-templates select="mei:titleStmt/mei:title[contains(@analog, 'marc:240') or
          contains(@type, 'uniform')]"/>
      </xsl:when>
      <xsl:when
        test="ancestor::mei:meiHead/mei:workDesc/mei:work/mei:titleStmt/mei:title[contains(@analog,
        'marc:240') or contains(@type, 'uniform')]">
        <xsl:apply-templates
          select="ancestor::mei:meiHead/mei:workDesc/mei:work/mei:titleStmt/mei:title[contains(@analog,
          'marc:240') or contains(@type, 'uniform')]"/>
      </xsl:when>
    </xsl:choose>

    <!-- Title Proper -->
    <xsl:choose>
      <xsl:when test="mei:titleStmt/mei:title[contains(@analog, 'marc:245')]">
        <xsl:apply-templates select="mei:titleStmt/mei:title[contains(@analog, 'marc:245')]"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="mei:titleStmt/mei:title[not(contains(@type, 'subtitle'))][1]"/>
      </xsl:otherwise>
    </xsl:choose>

    <!-- Publication -->
    <xsl:apply-templates select="mei:pubStmt"/>

    <!-- Physical Description -->

    <!-- Subject classification -->
    <xsl:apply-templates select="//mei:classification//mei:term[contains(@analog, 'marc:650')]"/>

    <!-- Added Entries -->
    <xsl:apply-templates select="mei:titleStmt/mei:respStmt/mei:persName[contains(@analog,
      'marc:700')]"/>
    <xsl:apply-templates select="mei:titleStmt/mei:respStmt/mei:persName[not(@analog) and
      not(contains(@role, 'creator') or contains(@role, 'composer'))] "/>
    <xsl:apply-templates select="mei:titleStmt/mei:respStmt/mei:corpName"/>
  </xsl:template>

  <xsl:template match="mei:term">
    <datafield>
      <xsl:variable name="tag">
        <xsl:value-of select="substring-after(@analog, ':')"/>
      </xsl:variable>
      <xsl:attribute name="tag">
        <xsl:value-of select="$tag"/>
      </xsl:attribute>
      <xsl:call-template name="indicators"/>
      <xsl:call-template name="subfield">
        <xsl:with-param name="code">a</xsl:with-param>
        <xsl:with-param name="value">
          <xsl:value-of select="."/>
        </xsl:with-param>
        <xsl:with-param name="delimiter">
          <xsl:choose>
            <xsl:when test="not($tag = '090')">
              <xsl:text>.</xsl:text>
            </xsl:when>
          </xsl:choose>
        </xsl:with-param>
      </xsl:call-template>
    </datafield>
  </xsl:template>

  <xsl:template match="mei:altId | mei:*[contains(@analog, 'marc:001')]">
    <xsl:call-template name="controlField">
      <xsl:with-param name="tag">001</xsl:with-param>
      <xsl:with-param name="value">
        <xsl:value-of select="."/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="mei:fileDesc/mei:pubStmt">
    <datafield>
      <xsl:attribute name="tag">
        <xsl:text>260</xsl:text>
      </xsl:attribute>
      <xsl:call-template name="indicators"/>
      <xsl:call-template name="subfield">
        <xsl:with-param name="code">a</xsl:with-param>
        <xsl:with-param name="value">
          <xsl:variable name="pubPlace">
            <xsl:for-each select="mei:address[1]">
              <xsl:for-each select="mei:addrLine">
                <xsl:value-of select="."/>
                <xsl:if test="position() != last()">
                  <xsl:text>, &#32;</xsl:text>
                </xsl:if>
              </xsl:for-each>
            </xsl:for-each>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="not($pubPlace = '')">
              <xsl:value-of select="normalize-space($pubPlace)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>[s.l.]</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
        <xsl:with-param name="delimiter"> : </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="subfield">
        <xsl:with-param name="code">b</xsl:with-param>
        <xsl:with-param name="value">
          <xsl:variable name="publisher">
            <xsl:value-of select="mei:respStmt"/>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="not($publisher = '')">
              <xsl:value-of select="mei:respStmt"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>[s.n.]</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
        <xsl:with-param name="delimiter">, </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="subfield">
        <xsl:with-param name="code">c</xsl:with-param>
        <xsl:with-param name="value">
          <xsl:choose>
            <xsl:when test="contains(mei:date, '-')">
              <xsl:value-of select="substring-before(mei:date, '-')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="mei:date"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
        <xsl:with-param name="delimiter">.</xsl:with-param>
      </xsl:call-template>
    </datafield>
  </xsl:template>

  <xsl:template name="indicators">
    <xsl:param name="ind1" xml:space="preserve">&#32;</xsl:param>
    <xsl:param name="ind2" xml:space="preserve">&#32;</xsl:param>
    <xsl:attribute name="ind1">
      <xsl:value-of select="$ind1"/>
    </xsl:attribute>
    <xsl:attribute name="ind2">
      <xsl:value-of select="$ind2"/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="mei:persName">
    <datafield>
      <xsl:attribute name="tag">
        <xsl:choose>
          <xsl:when test="@analog">
            <xsl:value-of select="substring-after(@analog, ':')"/>
          </xsl:when>
          <xsl:when test="contains(@role, 'composer') or contains(@role, 'creator')">
            <xsl:text>100</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>700</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:call-template name="indicators"/>
      <xsl:choose>
        <!-- Only text; subfield |a only  -->
        <xsl:when test="count(mei:*) = 0">
          <xsl:call-template name="subfield">
            <xsl:with-param name="code">a</xsl:with-param>
            <xsl:with-param name="value">
              <xsl:value-of select="."/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <!-- Mixed content; split into multiple subfields -->
        <xsl:otherwise>
          <xsl:call-template name="subfield">
            <xsl:with-param name="code">a</xsl:with-param>
              <xsl:with-param name="value">
                <xsl:variable name="name">
                  <xsl:value-of select="text()"/>
                </xsl:variable>
                <xsl:value-of select="normalize-space($name)"/>
            </xsl:with-param>
          </xsl:call-template>
          <xsl:call-template name="subfield">
            <xsl:with-param name="code">d</xsl:with-param>
            <xsl:with-param name="value">
              <xsl:value-of select="mei:date"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </datafield>
  </xsl:template>

  <xsl:template match="mei:corpName">
    <datafield>
      <xsl:attribute name="tag">
        <xsl:choose>
          <xsl:when test="@analog">
            <xsl:value-of select="substring-after(@analog, ':')"/>
          </xsl:when>
          <xsl:otherwise>710</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:call-template name="indicators"/>
      <xsl:choose>
        <!-- Only text; subfield |a only  -->
        <xsl:when test="count(mei:*) = 0">
          <xsl:call-template name="subfield">
            <xsl:with-param name="code">a</xsl:with-param>
            <xsl:with-param name="value">
              <xsl:value-of select="."/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <!-- Mixed content; split into multiple subfields -->
        <xsl:otherwise>
          <xsl:call-template name="subfield">
            <xsl:with-param name="code">a</xsl:with-param>
            <xsl:with-param name="value">
              <xsl:value-of select="text()"/>
            </xsl:with-param>
          </xsl:call-template>
          <xsl:call-template name="subfield">
            <xsl:with-param name="code">d</xsl:with-param>
            <xsl:with-param name="value">
              <xsl:value-of select="mei:date"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </datafield>
  </xsl:template>

  <xsl:template match="mei:title">
    <xsl:variable name="tag">
      <xsl:choose>
        <xsl:when test="@analog">
          <xsl:value-of select="substring-after(@analog, ':')"/>
        </xsl:when>
        <xsl:otherwise>245</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <datafield>
      <xsl:attribute name="tag" select="$tag"/>
      <xsl:call-template name="indicators"/>
      <xsl:call-template name="subfield">
        <xsl:with-param name="code">a</xsl:with-param>
        <xsl:with-param name="value">
          <xsl:value-of select="."/>
          <xsl:if test="$tag='245' and ../mei:title[contains(@type, 'subtitle')]">
            <xsl:for-each select="../mei:title[contains(@type, 'subtitle')]">
              <xsl:text> : </xsl:text>
              <xsl:value-of select="."/>
            </xsl:for-each>
          </xsl:if>
        </xsl:with-param>
      </xsl:call-template>
    </datafield>
  </xsl:template>

</xsl:stylesheet>
