//
//  HeartCell.swift
//  04_Diary
//
//  Created by Jacob Ko on 2021/12/16.
//

import UIKit


class HeartCell: UICollectionViewCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	
	// HeartCell border 생성
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		self.contentView.layer.cornerRadius = 20.0
		self.contentView.layer.backgroundColor = UIColor.systemGray4.cgColor
	}

}
