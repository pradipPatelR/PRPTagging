//
//  PRP_MentionHashTag_TextView.swift
//
//  Created by Pradip Patel on 25/6/21.
//  Copyright © 2021 Pradip Patel. All rights reserved.
//

import UIKit

//A custom text view that allows hashtags and @ symbols to be separated from the rest of the text and triggers actions upon selection

extension NSAttributedString.Key {
    
    fileprivate static var prpTagClickable: NSAttributedString.Key { return NSAttributedString.Key(rawValue: "prpTagClickable") }
    
    fileprivate static var prpTagClickableText: NSAttributedString.Key { return NSAttributedString.Key(rawValue: "prpTagClickableText") }
    
}

extension String {
    fileprivate var prp_nsstring: NSString {
        return NSString(string: self)
    }
    
    fileprivate var prp_isTrimingNull: String? {
        let str = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return str.count > 0 ? self : nil
    }
    
    fileprivate var prp_hashTagValidStrings : [(hashTag:String, getRange:NSRange)] {
        var arr_hasStrings:[(hashTag:String, getRange:NSRange)] = []
        let regex = try? NSRegularExpression(pattern: "(#[a-zA-Z0-9_\\p{Arabic}\\p{N}]*)", options: [])
        if let matches = regex?.matches(in: self, options:[], range:NSMakeRange(0, self.count)) {
            for match in matches {
                
                arr_hasStrings.append((self.prp_nsstring.substring(with: NSRange(location:match.range.location, length: match.range.length)), match.range))
            }
        }
        return arr_hasStrings
    }
    
}

struct ContainTaggedModel {
    let isDeleted: Bool
    let tagDisplayName: String
    let tagName: String
    let userId: String
    fileprivate var nsRange: NSRange
    
    fileprivate init(isDeleted: Bool, tagDisplayName: String, tagName: String, userId: String, nsRange: NSRange) {
        self.isDeleted = isDeleted
        self.tagDisplayName = tagDisplayName
        self.tagName = tagName
        self.userId = userId
        self.nsRange = nsRange
    }
    
    init(isDeleted: Bool, tagDisplayName: String, tagName: String, userId: String) {
        self.isDeleted = isDeleted
        self.tagDisplayName = tagDisplayName
        self.tagName = tagName
        self.userId = userId
        self.nsRange = .init()
    }
    
}

final class PRP_MentionHashTag_TextView: UITextView {
    
    enum RIGWordType {
        case hashtag
        case mention
    }
    

    var nsRangeList : [NSRange] = []
    var attrString: NSMutableAttributedString?
    var callBack: ((String, RIGWordType) -> Void)?
    var selectedLastRange : NSRange?
    fileprivate var hashTagColor : UIColor = .blue
   
    override func awakeFromNib() {
        super.awakeFromNib()

        self.isSelectable = false
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.copy) {
            return super.canPerformAction(action, withSender: sender)
        }
        if action == #selector(UIResponderStandardEditActions.select) {
            return super.canPerformAction(action, withSender: sender)
        }
        if action == #selector(UIResponderStandardEditActions.selectAll) {
            return super.canPerformAction(action, withSender: sender)
        }
        return false
    }
        
    
    public func setText(text: String, _containedTag : [ContainTaggedModel], withNormalColor normalColor: UIColor, andMentionColor mentionColor: UIColor, andCallBack callBack: @escaping (String, RIGWordType) -> Void, normalFont: UIFont, mentionFont: UIFont) {
        
        self.callBack = callBack
        self.nsRangeList = []
        self.selectedLastRange = nil
        self.hashTagColor = mentionColor
        
        var descrptionText = text
        
        let copy_containedTag = _containedTag.compactMap { (modelItem) -> ContainTaggedModel? in
            let range = descrptionText.prp_nsstring.range(of: modelItem.tagName)
            
            if range.location == NSNotFound {
                return nil
            }
            
            return ContainTaggedModel(isDeleted: modelItem.isDeleted, tagDisplayName: modelItem.tagDisplayName, tagName: modelItem.tagName, userId: modelItem.userId, nsRange: range)
        }
        
        var containedTag : [ContainTaggedModel] = copy_containedTag.sorted { (firstObj, secondObj) -> Bool in
            return firstObj.nsRange.location < secondObj.nsRange.location
        }
        
        for (index,obj) in containedTag.enumerated() {
            let newRangeLocation = descrptionText.prp_nsstring.range(of: obj.tagName)
            descrptionText = descrptionText.replacingOccurrences(of: obj.tagName, with: obj.tagDisplayName)
            containedTag[index].nsRange = NSMakeRange(newRangeLocation.location, obj.tagDisplayName.count)
        }
        
        self.text = descrptionText
        
        // Set initial font attributes for our string
        self.attrString = NSMutableAttributedString(string: descrptionText, attributes: [NSAttributedString.Key.font : normalFont, NSAttributedString.Key.foregroundColor : normalColor])
        
        self.attributedText = attrString
        
        for obj in containedTag {
            if !obj.isDeleted {
                setAttrWithName(userId: obj.userId, color: mentionColor, font: mentionFont, setRange: obj.nsRange)
            }
        }
        
        let hashTagList = descrptionText.prp_hashTagValidStrings.sorted { (first:(hashTag:String, getRange:NSRange), second:(hashTag:String, getRange:NSRange)) -> Bool in
            return first.getRange.location < second.getRange.location
        }
        
        for item in hashTagList {
            setAttrWithName(userId: item.hashTag, color: mentionColor, font: mentionFont, setRange: item.getRange)
        }

        let gestureHint = "my_prp_mention_hashTag"
        let gstList = self.gestureRecognizers?.filter({ $0.accessibilityHint == gestureHint })
        gstList?.forEach({ self.removeGestureRecognizer($0) })
        let tapper = UITapGestureRecognizer(target: self, action: #selector(tapRecognized))
        tapper.accessibilityHint = gestureHint
        addGestureRecognizer(tapper)
    }
    
    
    private func setAttrWithName(userId: String, color: UIColor, font: UIFont, setRange newRange: NSRange) {
        
        if newRange.location == NSNotFound {
            return
        }
        
        if !nsRangeList.contains(newRange) {
            nsRangeList.append(newRange)
        }
        
        attrString?.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: newRange)
        attrString?.addAttribute(NSAttributedString.Key.prpTagClickable, value: 1, range: newRange)
        attrString?.addAttribute(NSAttributedString.Key.prpTagClickableText, value: userId, range: newRange)
        attrString?.addAttribute(NSAttributedString.Key.font, value: font, range: newRange)
        
        self.attributedText = attrString
    }
    
    
    @objc func tapRecognized(tapGesture: UITapGestureRecognizer) {
        var wordString: String?         // The String value of the word to pass into callback functionZ
        var isClickable : Bool = false
        
        // Gets the range of the character at the place the user taps
        let point = tapGesture.location(in: self)
        
        guard let attrRange = attributedTextRange(for: point) else { return }
        
        //Checks if the user has tapped on a character.
        
        let char = attributedText.attributedSubstring(from: attrRange)
        
        // retrieve attributes
        let attributes = char.attributes(at: 0, effectiveRange: nil)
        
        // iterate each attribute
        
        if let value = attributes[.prpTagClickable] as? Int, value == 1 {
            isClickable = true
        }
        
        if let value = (attributes[.prpTagClickableText] as? String)?.prp_isTrimingNull {
            wordString = value
        }
        
        if let stringToPass = wordString?.prp_isTrimingNull, isClickable {
            // Runs callback function if word is a Hashtag or Mention
            if Int(stringToPass) == nil {
                callBack?(stringToPass, .hashtag)
            } else {
                callBack?(stringToPass, .mention)
            }
        }
    }
    
    
    //MARK: MENTION TAG AND HASH TAG CLICK EVENT HIGHLIGHT
    
    private func attributedTextRange(for point: CGPoint) -> NSRange? {
        
        guard let charPosition = closestPosition(to: point),
            let charRange = tokenizer.rangeEnclosingPosition(charPosition, with: .character, inDirection: UITextDirection(rawValue: 1)) else { return nil }
        
        let location = offset(from: beginningOfDocument, to: charRange.start)
        let length = offset(from: charRange.start, to: charRange.end)
        
        if location == NSNotFound {
            return nil
        }
        
        let tapNsRangeLocation = location + length
        
        for itemRange in nsRangeList {
            if (tapNsRangeLocation >= itemRange.location) && (tapNsRangeLocation <= (itemRange.location + itemRange.length)) {
                
                return itemRange
            }
        }
        
        return nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchPoint = touch.location(in: self)
            
            if let selectedItemRange = attributedTextRange(for: touchPoint) {
                self.selectedLastRange = selectedItemRange
                
                attrString?.addAttribute(NSAttributedString.Key.foregroundColor, value: hashTagColor.withAlphaComponent(0.7), range: selectedItemRange)

                UIView.transition(with: self, duration: 0.15, options: .transitionCrossDissolve, animations: {
                    self.attributedText = self.attrString
                })
                return
            }
        }
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchPoint = touch.location(in: self)
            let newSelectedItemRange = attributedTextRange(for: touchPoint)
            
            if let getSelectedLastRange = self.selectedLastRange,
                getSelectedLastRange != newSelectedItemRange {
                
                attrString?.addAttribute(NSAttributedString.Key.foregroundColor, value: hashTagColor, range: getSelectedLastRange)
                
                self.selectedLastRange = nil
                UIView.transition(with: self, duration: 0.15, options: .transitionCrossDissolve, animations: {
                    self.attributedText = self.attrString
                })
            }
        }
        super.touchesMoved(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let getSelectedLastRange = self.selectedLastRange {
            
            attrString?.addAttribute(NSAttributedString.Key.foregroundColor, value: hashTagColor, range: getSelectedLastRange)
            
            self.selectedLastRange = nil
            UIView.transition(with: self, duration: 0.15, options: .transitionCrossDissolve, animations: {
                self.attributedText = self.attrString
            })
        }
        super.touchesCancelled(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let getSelectedLastRange = self.selectedLastRange {
            
            attrString?.addAttribute(NSAttributedString.Key.foregroundColor, value: hashTagColor, range: getSelectedLastRange)
            
            self.selectedLastRange = nil
            UIView.transition(with: self, duration: 0.15, options: .transitionCrossDissolve, animations: {
                self.attributedText = self.attrString
            })
        }
        super.touchesEnded(touches, with: event)
    }
}

