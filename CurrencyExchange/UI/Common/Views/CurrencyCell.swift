import UIKit

class CurrencyCell: UITableViewCell {
    static let reuseIdentifier = "CurrencyCell"
    
    private let currencyCodeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .appText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let currencyNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let rateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = .appText
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.roundCorners(radius: 10)
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(currencyCodeLabel)
        containerView.addSubview(currencyNameLabel)
        containerView.addSubview(rateLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            currencyCodeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            currencyCodeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            currencyNameLabel.topAnchor.constraint(equalTo: currencyCodeLabel.bottomAnchor, constant: 4),
            currencyNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            currencyNameLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            rateLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            rateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            rateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: currencyNameLabel.trailingAnchor, constant: 8)
        ])
        
        containerView.addShadow(opacity: 0.1, radius: 2, offset: CGSize(width: 0, height: 1))
    }
    
    func configure(currencyCode: String, currencyName: String?, rate: Double) {
        currencyCodeLabel.text = currencyCode
        currencyNameLabel.text = currencyName ?? currencyCode
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        
        if let formattedRate = formatter.string(from: NSNumber(value: rate)) {
            rateLabel.text = formattedRate
        } else {
            rateLabel.text = String(format: "%.4f", rate)
        }
    }
}
