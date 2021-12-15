//
//  DiaryCell.swift
//  04_Diary
//
//  Created by Jacob Ko on 2021/12/15.
//

import UIKit

class DiaryCell: UICollectionViewCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	
	// UIView 가 storyView 나 code 로 생성이 될때, 이 생성자를 통해 객체가 생성됨
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		// diary cell 의 borderline 만들기
		self.contentView.layer.cornerRadius = 20.0
		self.contentView.layer.borderWidth = 1.0
		self.contentView.layer.borderColor = UIColor.darkGray.cgColor
	}

}
