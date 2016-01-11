//
//  NewTodoItemCell.swift
//  Todo
//
//  Created by Chi Zhang on 1/4/16.
//  Copyright © 2016 chi zhang. All rights reserved.
//

import UIKit

class NewTodoItemCell: UITableViewCell {
    
    @IBOutlet weak var cardBackgroundView: UIView!
    @IBOutlet weak var textView: UITextView!
    
    @IBAction func okTouched(sender: UIButton) {
        self.actionTriggered?(self, .OK)
    }
    
    @IBAction func cancelTouched(sender: UIButton) {
        self.actionTriggered?(self, .Cancel)
    }
    
    enum Action {
        case OK
        case Cancel
    }
    
    var actionTriggered: ((NewTodoItemCell, Action)->())?
    
    override func awakeFromNib() {
        // set background colors so the cell background can show
        self.backgroundColor = UIColor.clearColor()
        self.contentView.backgroundColor = UIColor.clearColor()
        self.cardBackgroundView.layer.cornerRadius = 5.0
        self.cardBackgroundView.clipsToBounds = true
    }
}