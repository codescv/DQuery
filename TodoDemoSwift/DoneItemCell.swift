//
//  DoneItemCell.swift
//  Todo
//
//  Created by Chi Zhang on 1/5/16.
//  Copyright © 2016 chi zhang. All rights reserved.
//

import UIKit

class DoneItemCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var cardBackgroundView: UIView!
    
    @IBAction func deleteAction(sender: AnyObject) {
        self.actionTriggered?(self, .Delete)
    }
    
    enum Action {
        case Delete
    }
    
    var actionTriggered: ((DoneItemCell, Action)->())?
    
    override func awakeFromNib() {
        // set background colors so the cell background can show
        self.backgroundColor = UIColor.clearColor()
        self.contentView.backgroundColor = UIColor.clearColor()
        self.cardBackgroundView.layer.cornerRadius = 5.0
        self.cardBackgroundView.clipsToBounds = true
    }
    
    func configureWithViewModel(viewModel: TodoItemViewModel) {
        self.titleLabel.text = viewModel.title
    }
}
