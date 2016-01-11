//
// Copyright 2016 DQuery
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  TodoItemCell.swift
//
//  Created by chi on 16/1/10.
//

import UIKit

class TodoItemCell: UITableViewCell {
    enum Action {
        case MarkAsDone
    }
    
    var actionTriggered: ((TodoItemCell, Action)->())?
    
    @IBOutlet weak var cardBackgroundView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBAction func markAsDone(sender: AnyObject) {
        self.actionTriggered?(self, .MarkAsDone)
    }

    func configureWithViewModel(todoItemViewModel: TodoItemViewModel) {
        self.titleLabel.text = todoItemViewModel.title
    }
    
    override func awakeFromNib() {
        // set background colors so the cell background can show
        self.backgroundColor = UIColor.clearColor()
        self.contentView.backgroundColor = UIColor.clearColor()
        self.cardBackgroundView.layer.cornerRadius = 5.0
        self.cardBackgroundView.clipsToBounds = true
    }
}