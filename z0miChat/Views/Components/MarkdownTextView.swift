//
//  MarkdownTextView.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//


import SwiftUI
import UIKit

struct MarkdownTextView: View {
    let text: String
    
    var body: some View {
        MarkdownText(markdown: text)
            .lineLimit(nil)
    }
}

// Markdown renderer
struct MarkdownText: View {
    let markdown: String
    
    var body: some View {
        let attributedString = parseMarkdown(markdown)
        return Text(AttributedString(attributedString))
    }
    
    private func parseMarkdown(_ markdownText: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        
        // Create the initial attributed string with paragraph style
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: UIFont.systemFontSize)
        ]
        
        let attributedString = NSMutableAttributedString(string: markdownText, attributes: defaultAttributes)
        
        // Process code blocks first to avoid interference with other formatting
        processCodeBlocks(attributedString)
        
        // Process inline code
        processInlineCode(attributedString)
        
        // Process headers
        processHeaders(attributedString)
        
        // Process bold text
        processBoldText(attributedString)
        
        // Process italic text
        processItalicText(attributedString)
        
        // Process lists
        processLists(attributedString)
        
        // Process links
        processLinks(attributedString)
        
        return attributedString
    }
    
    // MARK: - Markdown Element Processors
    
    private func processCodeBlocks(_ attributedString: NSMutableAttributedString) {
        let codeBlockPattern = "```([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: []) else {
            return
        }
        
        let text = attributedString.string
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        let codeFont = UIFont.monospacedSystemFont(ofSize: UIFont.systemFontSize, weight: .regular)
        
        for match in matches.reversed() {
            let codeBlockRange = match.range
            
            // Apply code block formatting
            attributedString.addAttribute(.font, value: codeFont, range: codeBlockRange)
            attributedString.addAttribute(.backgroundColor, value: UIColor.systemGray6, range: codeBlockRange)
        }
    }
    
    private func processInlineCode(_ attributedString: NSMutableAttributedString) {
        let inlineCodePattern = "`([^`]+)`"
        guard let regex = try? NSRegularExpression(pattern: inlineCodePattern, options: []) else {
            return
        }
        
        let text = attributedString.string
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        let codeFont = UIFont.monospacedSystemFont(ofSize: UIFont.systemFontSize, weight: .regular)
        
        for match in matches.reversed() {
            let inlineCodeRange = match.range
            
            // Apply inline code formatting
            attributedString.addAttribute(.font, value: codeFont, range: inlineCodeRange)
            attributedString.addAttribute(.backgroundColor, value: UIColor.systemGray6, range: inlineCodeRange)
        }
    }
    
    private func processHeaders(_ attributedString: NSMutableAttributedString) {
        // Process H1
        processHeaderLevel(attributedString, pattern: "^# (.+)$", fontSize: UIFont.systemFontSize * 1.5)
        
        // Process H2
        processHeaderLevel(attributedString, pattern: "^## (.+)$", fontSize: UIFont.systemFontSize * 1.3)
        
        // Process H3
        processHeaderLevel(attributedString, pattern: "^### (.+)$", fontSize: UIFont.systemFontSize * 1.1)
    }
    
    private func processHeaderLevel(_ attributedString: NSMutableAttributedString, pattern: String, fontSize: CGFloat) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
            return
        }
        
        let text = attributedString.string
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        let headerFont = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        
        for match in matches.reversed() {
            if match.numberOfRanges > 1 {
                let headerTextRange = match.range(at: 1)  // Capture the text after the # markers
                attributedString.addAttribute(.font, value: headerFont, range: headerTextRange)
            }
        }
    }
    
    private func processBoldText(_ attributedString: NSMutableAttributedString) {
        // Process **bold text**
        processBoldPattern(attributedString, pattern: "\\*\\*([^\\*\\n]+)\\*\\*")
        
        // Process __bold text__
        processBoldPattern(attributedString, pattern: "__([^_\\n]+)__")
    }
    
    private func processBoldPattern(_ attributedString: NSMutableAttributedString, pattern: String) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return
        }
        
        let text = attributedString.string
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        let boldFont = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .bold)
        
        for match in matches.reversed() {
            if match.numberOfRanges > 1 {
                let fullRange = match.range
                let contentRange = match.range(at: 1)
                
                // Remove the bold markers
                let boldText = (text as NSString).substring(with: contentRange)
                attributedString.replaceCharacters(in: fullRange, with: boldText)
                
                // Apply bold formatting to the replaced text
                // We need to adjust the range since we've modified the string
                let newRange = NSRange(location: fullRange.location, length: boldText.count)
                attributedString.addAttribute(.font, value: boldFont, range: newRange)
            }
        }
    }
    
    private func processItalicText(_ attributedString: NSMutableAttributedString) {
        // Process *italic text*
        processItalicPattern(attributedString, pattern: "\\*([^\\*\\n]+)\\*")
        
        // Process _italic text_
        processItalicPattern(attributedString, pattern: "_([^_\\n]+)_")
    }
    
    private func processItalicPattern(_ attributedString: NSMutableAttributedString, pattern: String) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return
        }
        
        let text = attributedString.string
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        let italicFont = UIFont.italicSystemFont(ofSize: UIFont.systemFontSize)
        
        for match in matches.reversed() {
            if match.numberOfRanges > 1 {
                let fullRange = match.range
                let contentRange = match.range(at: 1)
                
                // Remove the italic markers
                let italicText = (text as NSString).substring(with: contentRange)
                attributedString.replaceCharacters(in: fullRange, with: italicText)
                
                // Apply italic formatting to the replaced text
                // We need to adjust the range since we've modified the string
                let newRange = NSRange(location: fullRange.location, length: italicText.count)
                attributedString.addAttribute(.font, value: italicFont, range: newRange)
            }
        }
    }
    
    private func processLists(_ attributedString: NSMutableAttributedString) {
        let listPattern = "^(\\s*)([*-]) (.+)$"
        guard let regex = try? NSRegularExpression(pattern: listPattern, options: [.anchorsMatchLines]) else {
            return
        }
        
        let text = attributedString.string
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        for match in matches.reversed() {
            if match.numberOfRanges >= 4 {
                let fullRange = match.range
                let indentRange = match.range(at: 1)
                let markerRange = match.range(at: 2)
                let contentRange = match.range(at: 3)
                
                let indent = (text as NSString).substring(with: indentRange)
                let content = (text as NSString).substring(with: contentRange)
                
                // Create bullet point with proper indentation
                let bulletPoint = "\(indent)• "
                let listItemText = "\(bulletPoint)\(content)"
                
                attributedString.replaceCharacters(in: fullRange, with: listItemText)
            }
        }
    }
    
    private func processLinks(_ attributedString: NSMutableAttributedString) {
        let linkPattern = "\\[([^\\]]+)\\]\\(([^\\)]+)\\)"
        guard let regex = try? NSRegularExpression(pattern: linkPattern, options: []) else {
            return
        }
        
        let text = attributedString.string
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        for match in matches.reversed() {
            if match.numberOfRanges >= 3 {
                let fullRange = match.range
                let textRange = match.range(at: 1)
                let urlRange = match.range(at: 2)
                
                let linkText = (text as NSString).substring(with: textRange)
                let urlText = (text as NSString).substring(with: urlRange)
                
                // Replace the markdown link with just the link text
                attributedString.replaceCharacters(in: fullRange, with: linkText)
                
                // Apply link attributes to the new range
                let newRange = NSRange(location: fullRange.location, length: linkText.count)
                attributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: newRange)
                attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: newRange)
                
                // Add the actual link if it's a valid URL
                if let url = URL(string: urlText) {
                    attributedString.addAttribute(.link, value: url, range: newRange)
                }
            }
        }
    }
}

struct MarkdownTextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 20) {
            MarkdownTextView(text: "# Heading 1\n## Heading 2\n### Heading 3")
            MarkdownTextView(text: "**Bold text** and *italic text*")
            MarkdownTextView(text: "- List item 1\n- List item 2\n  - Nested item")
            MarkdownTextView(text: "Code block: ```let x = 10```")
            MarkdownTextView(text: "Link: [Google](https://google.com)")
        }
        .padding()
    }
}
