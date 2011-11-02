# encoding: utf-8
require 'zip/zip'

module Spreet
  module Handlers
    class OpenDocument < Spreet::Handler
      DATE_REGEXP = /\%./
      DATE_ELEMENTS = {
        "m" => "<number:month number:style=\"long\"/>",
        "d" => "<number:day number:style=\"long\"/>",
        "Y" => "<number:year/>"
      }


      def self.mimetype
      end

      def self.xmlec(string)
        zs = string.to_s.gsub('&', '&amp;').gsub('\'', '&apos;').gsub('<', '&lt;').gsub('>', '&gt;')
        zs.force_encoding('US-ASCII') if zs.respond_to?(:force_encoding)
        return zs
      end


      def self.write(spreet, file, options={})
        xml_escape = "to_s.gsub('&', '&amp;').gsub('\\'', '&apos;').gsub('<', '&lt;').gsub('>', '&gt;')"
        xml_escape << ".force_encoding('US-ASCII')" if xml_escape.respond_to?(:force_encoding)
        mimetype = "application/vnd.oasis.opendocument.spreadsheet"
        # name = #{table.model.name}.model_name.human.gsub(/[^a-z0-9]/i,'_')
        Zip::ZipOutputStream.open(file) do |zile|
          # MimeType in first place
          zile.put_next_entry('mimetype', nil, nil, Zip::ZipEntry::STORED)
          zile << mimetype
          
          # Manifest
          zile.put_next_entry('META-INF/manifest.xml')
          zile << ("<?xml version=\"1.0\" encoding=\"UTF-8\"?><manifest:manifest xmlns:manifest=\"urn:oasis:names:tc:opendocument:xmlns:manifest:1.0\"><manifest:file-entry manifest:media-type=\"#{mimetype}\" manifest:full-path=\"/\"/><manifest:file-entry manifest:media-type=\"text/xml\" manifest:full-path=\"content.xml\"/></manifest:manifest>")
          zile.put_next_entry('content.xml')
        
          zile << ("<?xml version=\"1.0\" encoding=\"UTF-8\"?><office:document-content xmlns:office=\"urn:oasis:names:tc:opendocument:xmlns:office:1.0\" xmlns:style=\"urn:oasis:names:tc:opendocument:xmlns:style:1.0\" xmlns:text=\"urn:oasis:names:tc:opendocument:xmlns:text:1.0\" xmlns:table=\"urn:oasis:names:tc:opendocument:xmlns:table:1.0\" xmlns:draw=\"urn:oasis:names:tc:opendocument:xmlns:drawing:1.0\" xmlns:fo=\"urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:meta=\"urn:oasis:names:tc:opendocument:xmlns:meta:1.0\" xmlns:number=\"urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0\" xmlns:presentation=\"urn:oasis:names:tc:opendocument:xmlns:presentation:1.0\" xmlns:svg=\"urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0\" xmlns:chart=\"urn:oasis:names:tc:opendocument:xmlns:chart:1.0\" xmlns:dr3d=\"urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0\" xmlns:math=\"http://www.w3.org/1998/Math/MathML\" xmlns:form=\"urn:oasis:names:tc:opendocument:xmlns:form:1.0\" xmlns:script=\"urn:oasis:names:tc:opendocument:xmlns:script:1.0\" xmlns:ooo=\"http://openoffice.org/2004/office\" xmlns:ooow=\"http://openoffice.org/2004/writer\" xmlns:oooc=\"http://openoffice.org/2004/calc\" xmlns:dom=\"http://www.w3.org/2001/xml-events\" xmlns:xforms=\"http://www.w3.org/2002/xforms\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:field=\"urn:openoffice:names:experimental:ooxml-odf-interop:xmlns:field:1.0\" office:version=\"1.1\"><office:scripts/>")
          # Styles
          default_date_format = '%d/%m%Y' # ::I18n.translate("date.formats.default")
          zile << ("<office:automatic-styles><style:style style:name=\"co1\" style:family=\"table-column\"><style:table-column-properties fo:break-before=\"auto\" style:use-optimal-column-width=\"true\"/></style:style><style:style style:name=\"header\" style:family=\"table-cell\"><style:text-properties fo:font-weight=\"bold\" style:font-weight-asian=\"bold\" style:font-weight-complex=\"bold\"/></style:style><number:date-style style:name=\"K4D\" number:automatic-order=\"true\"><number:text>"+default_date_format.gsub(DATE_REGEXP){|x| "</number:text>"+DATE_ELEMENTS[x[1..1]]+"<number:text>"} +"</number:text></number:date-style><style:style style:name=\"ce1\" style:family=\"table-cell\" style:data-style-name=\"K4D\"/></office:automatic-styles>")
        
          zile << ("<office:body><office:spreadsheet>")
          # Tables
          for sheet in spreet.sheets
            zile << ("<table:table table:name=\"#{xmlec(sheet.name)}\">")
            zile << ("<table:table-column table:number-columns-repeated=\"#{sheet.bound.x+1}\"/>")
            # zile << ("<table:table-header-rows><table:table-row>"+columns_headers(table).collect{|h| "<table:table-cell table:style-name=\"header\" office:value-type=\"string\"><text:p>'+(#{h}).#{xml_escape}+'</text:p></table:table-cell>"}.join+"</table:table-row></table:table-header-rows>")
            sheet.each_row do |row| # #{record} in #{table.records_variable_name}\n"
              zile << "<table:table-row>"
              for cell in row
                zile << "<table:table-cell"+(if cell.type == :decimal
                                               " office:value-type=\"float\" office:value=\"#{xmlec(cell.value)}\""
                                             elsif cell.type == :boolean
                                               " office:value-type=\"boolean\" office:boolean-value=\"#{xmlec(cell.value ? 'true' : 'false')}\""
                                             elsif cell.type == :date
                                               " office:value-type=\"date\" table:style-name=\"ce1\" office:date-value=\"#{xmlec(cell.value)}\""
                                             else
                                               " office:value-type=\"string\""
                                             end)+"><text:p>"+xmlec(cell.text)+"</text:p></table:table-cell>"
              end
              zile << "</table:table-row>"
            end
            zile << ("</table:table>")
          end
          zile << ("</office:spreadsheet></office:body></office:document-content>")
        end
        # Zile is finished
      end
      
      
    end
  end
end
