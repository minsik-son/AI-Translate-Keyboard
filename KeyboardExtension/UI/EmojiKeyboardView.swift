import UIKit

class EmojiKeyboardView: UIView {

    var onEmojiSelected: ((String) -> Void)?
    var onBackToKeyboard: (() -> Void)?

    private var isDark = false
    private var currentCategoryIndex = 0

    // MARK: - Emoji Categories

    private struct EmojiCategory {
        let icon: String      // SF Symbol name
        let emojis: [String]
    }

    private let categories: [EmojiCategory] = [
        EmojiCategory(icon: "face.smiling", emojis: [
            "😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂",
            "🙂", "🙃", "😉", "😊", "😇", "🥰", "😍", "🤩",
            "😘", "😗", "☺️", "😚", "😙", "🥲", "😋", "😛",
            "😜", "🤪", "😝", "🤑", "🤗", "🤭", "🤫", "🤔",
            "🫡", "🤐", "🤨", "😐", "😑", "😶", "🫥", "😏",
            "😒", "🙄", "😬", "🤥", "😌", "😔", "😪", "🤤",
            "😴", "😷", "🤒", "🤕", "🤢", "🤮", "🥵", "🥶",
            "🥴", "😵", "🤯", "🤠", "🥳", "🥸", "😎", "🤓",
            "🧐", "😕", "🫤", "😟", "🙁", "☹️", "😮", "😯",
            "😲", "😳", "🥺", "🥹", "😦", "😧", "😨", "😰",
            "😥", "😢", "😭", "😱", "😖", "😣", "😞", "😓",
            "😩", "😫", "🥱", "😤", "😡", "😠", "🤬", "😈",
            "👿", "💀", "☠️", "💩", "🤡", "👹", "👺", "👻",
            "👽", "👾", "🤖", "😺", "😸", "😹", "😻", "😼",
            "😽", "🙀", "😿", "😾", "🙈", "🙉", "🙊", "💋",
            "💌", "💘", "💝", "💖", "💗", "💓", "💞", "💕",
            "💟", "❣️", "💔", "❤️‍🔥", "❤️‍🩹", "❤️", "🧡", "💛",
            "💚", "💙", "💜", "🤎", "🖤", "🤍", "💯", "💢",
            "👋", "🤚", "🖐️", "✋", "🖖", "🫱", "🫲", "🫳",
            "🫴", "👌", "🤌", "🤏", "✌️", "🤞", "🫰", "🤟",
            "🤘", "🤙", "👈", "👉", "👆", "🖕", "👇", "☝️",
            "🫵", "👍", "👎", "✊", "👊", "🤛", "🤜", "👏",
            "🙌", "🫶", "👐", "🤲", "🤝", "🙏", "✍️", "💅",
        ]),
        EmojiCategory(icon: "pawprint.fill", emojis: [
            "🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼",
            "🐻‍❄️", "🐨", "🐯", "🦁", "🐮", "🐷", "🐸", "🐵",
            "🙈", "🙉", "🙊", "🐒", "🐔", "🐧", "🐦", "🐤",
            "🐣", "🐥", "🦆", "🦅", "🦉", "🦇", "🐺", "🐗",
            "🐴", "🦄", "🐝", "🪱", "🐛", "🦋", "🐌", "🐞",
            "🐜", "🪰", "🪲", "🪳", "🦟", "🦗", "🕷️", "🕸️",
            "🦂", "🐢", "🐍", "🦎", "🦖", "🦕", "🐙", "🦑",
            "🦐", "🦞", "🦀", "🐡", "🐠", "🐟", "🐬", "🐳",
            "🐋", "🦈", "🐊", "🐅", "🐆", "🦓", "🦍", "🦧",
            "🦣", "🐘", "🦛", "🦏", "🐪", "🐫", "🦒", "🦘",
            "🦬", "🐃", "🐂", "🐄", "🐎", "🐖", "🐏", "🐑",
            "🦙", "🐐", "🦌", "🐕", "🐩", "🦮", "🐕‍🦺", "🐈",
            "🌵", "🎄", "🌲", "🌳", "🌴", "🪵", "🌱", "🌿",
            "☘️", "🍀", "🎍", "🪴", "🎋", "🍃", "🍂", "🍁",
            "🌾", "🌺", "🌻", "🌹", "🥀", "🌷", "🌼", "🌸",
            "💐", "🍄", "🌰", "🎃", "🐚", "🪸", "🪨", "🌎",
        ]),
        EmojiCategory(icon: "fork.knife", emojis: [
            "🍏", "🍎", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇",
            "🍓", "🫐", "🍈", "🍒", "🍑", "🥭", "🍍", "🥥",
            "🥝", "🍅", "🍆", "🥑", "🥦", "🥬", "🥒", "🌶️",
            "🫑", "🌽", "🥕", "🫒", "🧄", "🧅", "🥔", "🍠",
            "🫘", "🥐", "🍞", "🥖", "🥨", "🧀", "🥚", "🍳",
            "🧈", "🥞", "🧇", "🥓", "🥩", "🍗", "🍖", "🌭",
            "🍔", "🍟", "🍕", "🫓", "🥪", "🥙", "🧆", "🌮",
            "🌯", "🫔", "🥗", "🥘", "🫕", "🥫", "🍝", "🍜",
            "🍲", "🍛", "🍣", "🍱", "🥟", "🦪", "🍤", "🍙",
            "🍚", "🍘", "🍥", "🥠", "🥮", "🍢", "🍡", "🍧",
            "🍨", "🍦", "🥧", "🧁", "🍰", "🎂", "🍮", "🍭",
            "🍬", "🍫", "🍿", "🍩", "🍪", "🌰", "🥜", "🍯",
            "🥛", "🍼", "🫖", "☕", "🍵", "🧃", "🥤", "🧋",
            "🍶", "🍺", "🍻", "🥂", "🍷", "🥃", "🍸", "🍹",
            "🧉", "🍾", "🧊", "🥄", "🍴", "🍽️", "🥣", "🥡",
        ]),
        EmojiCategory(icon: "sportscourt.fill", emojis: [
            "⚽", "🏀", "🏈", "⚾", "🥎", "🎾", "🏐", "🏉",
            "🥏", "🎱", "🪀", "🏓", "🏸", "🏒", "🏑", "🥍",
            "🏏", "🪃", "🥅", "⛳", "🪁", "🏹", "🎣", "🤿",
            "🥊", "🥋", "🎽", "🛹", "🛼", "🛷", "⛸️", "🥌",
            "🎿", "⛷️", "🏂", "🪂", "🏋️", "🤼", "🤸", "🤺",
            "⛹️", "🤾", "🏌️", "🏇", "🧘", "🏄", "🏊", "🤽",
            "🚣", "🧗", "🚵", "🚴", "🏆", "🥇", "🥈", "🥉",
            "🏅", "🎖️", "🏵️", "🎗️", "🎫", "🎟️", "🎪", "🤹",
            "🎭", "🩰", "🎨", "🎬", "🎤", "🎧", "🎼", "🎹",
            "🥁", "🪘", "🎷", "🎺", "🪗", "🎸", "🪕", "🎻",
            "🎲", "♟️", "🎯", "🎳", "🎮", "🕹️", "🧩", "🪄",
        ]),
        EmojiCategory(icon: "car.fill", emojis: [
            "🚗", "🚕", "🚙", "🚌", "🚎", "🏎️", "🚓", "🚑",
            "🚒", "🚐", "🛻", "🚚", "🚛", "🚜", "🛵", "🏍️",
            "🛺", "🚲", "🛴", "🛹", "🚏", "🛣️", "🛤️", "🛞",
            "⛽", "🚨", "🚥", "🚦", "🛑", "🚧", "⚓", "🛟",
            "⛵", "🛶", "🚤", "🛳️", "⛴️", "🛥️", "🚢", "✈️",
            "🛩️", "🛫", "🛬", "🪂", "💺", "🚁", "🚟", "🚠",
            "🚡", "🛰️", "🚀", "🛸", "🌍", "🌎", "🌏", "🌐",
            "🗺️", "🧭", "🏔️", "⛰️", "🌋", "🗻", "🏕️", "🏖️",
            "🏜️", "🏝️", "🏞️", "🏟️", "🏛️", "🏗️", "🧱", "🪨",
            "🪵", "🛖", "🏘️", "🏚️", "🏠", "🏡", "🏢", "🏣",
            "🏤", "🏥", "🏦", "🏨", "🏩", "🏪", "🏫", "🏬",
            "🏭", "🏯", "🏰", "💒", "🗼", "🗽", "⛪", "🕌",
            "🛕", "🕍", "⛩️", "🕋", "⛲", "⛺", "🌁", "🌃",
            "🏙️", "🌄", "🌅", "🌆", "🌇", "🌉", "♨️", "🎠",
            "🛝", "🎡", "🎢", "💈", "🎪", "🚂", "🚃", "🚄",
            "🚅", "🚆", "🚇", "🚈", "🚉", "🚊", "🚝", "🚞",
        ]),
        EmojiCategory(icon: "lightbulb.fill", emojis: [
            "⌚", "📱", "📲", "💻", "⌨️", "🖥️", "🖨️", "🖱️",
            "🖲️", "💽", "💾", "💿", "📀", "🧮", "🎥", "🎞️",
            "📽️", "🎬", "📺", "📷", "📸", "📹", "📼", "🔍",
            "🔎", "🕯️", "💡", "🔦", "🏮", "🪔", "📔", "📕",
            "📖", "📗", "📘", "📙", "📚", "📓", "📒", "📃",
            "📜", "📄", "📰", "🗞️", "📑", "🔖", "🏷️", "💰",
            "🪙", "💴", "💵", "💶", "💷", "💸", "💳", "🧾",
            "💹", "✉️", "📧", "📨", "📩", "📤", "📥", "📦",
            "📫", "📪", "📬", "📭", "📮", "🗳️", "✏️", "✒️",
            "🖋️", "🖊️", "🖌️", "🖍️", "📝", "💼", "📁", "📂",
            "🗂️", "📅", "📆", "🗒️", "🗓️", "📇", "📈", "📉",
            "📊", "📋", "📌", "📍", "📎", "🖇️", "📏", "📐",
            "✂️", "🗃️", "🗄️", "🗑️", "🔒", "🔓", "🔏", "🔐",
            "🔑", "🗝️", "🔨", "🪓", "⛏️", "⚒️", "🛠️", "🗡️",
            "⚔️", "🔫", "🪃", "🏹", "🛡️", "🪚", "🔧", "🪛",
            "🔩", "⚙️", "🗜️", "⚖️", "🦯", "🔗", "⛓️", "🪝",
        ]),
        EmojiCategory(icon: "number.circle.fill", emojis: [
            "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍",
            "🤎", "❤️‍🔥", "❤️‍🩹", "💔", "❣️", "💕", "💞", "💓",
            "💗", "💖", "💝", "💘", "💟", "☮️", "✝️", "☪️",
            "🕉️", "☸️", "✡️", "🔯", "🕎", "☯️", "☦️", "🛐",
            "⛎", "♈", "♉", "♊", "♋", "♌", "♍", "♎",
            "♏", "♐", "♑", "♒", "♓", "🆔", "⚛️", "🉑",
            "☢️", "☣️", "📴", "📳", "🈶", "🈚", "🈸", "🈺",
            "🈷️", "✴️", "🆚", "💮", "🉐", "㊙️", "㊗️", "🈴",
            "🈵", "🈹", "🈲", "🅰️", "🅱️", "🆎", "🆑", "🅾️",
            "🆘", "❌", "⭕", "🛑", "⛔", "📛", "🚫", "💯",
            "💢", "♨️", "🚷", "🚯", "🚳", "🚱", "🔞", "📵",
            "🚭", "❗", "❕", "❓", "❔", "‼️", "⁉️", "🔅",
            "🔆", "〽️", "⚠️", "🚸", "🔱", "⚜️", "🔰", "♻️",
            "✅", "🈯", "💹", "❇️", "✳️", "❎", "🌐", "💠",
            "Ⓜ️", "🌀", "💤", "🏧", "🚾", "♿", "🅿️", "🛗",
            "🈳", "🈂️", "🛂", "🛃", "🛄", "🛅", "🚹", "🚺",
        ]),
        EmojiCategory(icon: "flag.fill", emojis: [
            "🏁", "🚩", "🎌", "🏴", "🏳️", "🏳️‍🌈", "🏳️‍⚧️", "🏴‍☠️",
            "🇰🇷", "🇺🇸", "🇯🇵", "🇨🇳", "🇬🇧", "🇫🇷", "🇩🇪", "🇮🇹",
            "🇪🇸", "🇵🇹", "🇧🇷", "🇷🇺", "🇮🇳", "🇦🇺", "🇨🇦", "🇲🇽",
            "🇹🇷", "🇸🇦", "🇦🇪", "🇹🇭", "🇻🇳", "🇮🇩", "🇲🇾", "🇸🇬",
            "🇵🇭", "🇳🇿", "🇦🇷", "🇨🇱", "🇨🇴", "🇵🇪", "🇪🇬", "🇿🇦",
            "🇳🇬", "🇰🇪", "🇪🇹", "🇬🇭", "🇹🇼", "🇭🇰", "🇲🇴", "🇲🇳",
            "🇰🇵", "🇰🇭", "🇱🇦", "🇲🇲", "🇧🇩", "🇵🇰", "🇦🇫", "🇮🇶",
            "🇮🇷", "🇮🇱", "🇵🇸", "🇱🇧", "🇯🇴", "🇸🇾", "🇾🇪", "🇴🇲",
        ]),
    ]

    // MARK: - Views

    private let collectionView: UICollectionView = {
        let layout = UIFlowLayout()
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.register(EmojiCell.self, forCellWithReuseIdentifier: "EmojiCell")
        return cv
    }()

    private let categoryBar: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let categoryStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .equalSpacing
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private var abcButton: UIButton!
    private var backspaceButton: UIButton!
    private var categoryButtons: [UIButton] = []

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        addSubview(collectionView)
        addSubview(categoryBar)
        categoryBar.addSubview(categoryStack)

        collectionView.dataSource = self
        collectionView.delegate = self

        // ABC button
        abcButton = UIButton(type: .system)
        abcButton.setTitle("ABC", for: .normal)
        abcButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        abcButton.addTarget(self, action: #selector(abcTapped), for: .touchUpInside)
        abcButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            abcButton.widthAnchor.constraint(equalToConstant: 36),
            abcButton.heightAnchor.constraint(equalToConstant: 40),
        ])
        categoryStack.addArrangedSubview(abcButton)

        // Category buttons
        for (index, category) in categories.enumerated() {
            let btn = UIButton(type: .system)
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
            btn.setImage(UIImage(systemName: category.icon, withConfiguration: config), for: .normal)
            btn.tag = index
            btn.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
            btn.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                btn.widthAnchor.constraint(equalToConstant: 32),
                btn.heightAnchor.constraint(equalToConstant: 40),
            ])
            categoryStack.addArrangedSubview(btn)
            categoryButtons.append(btn)
        }

        // Backspace button
        backspaceButton = UIButton(type: .system)
        let bsConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        backspaceButton.setImage(UIImage(systemName: "delete.left", withConfiguration: bsConfig), for: .normal)
        backspaceButton.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)
        backspaceButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backspaceButton.widthAnchor.constraint(equalToConstant: 36),
            backspaceButton.heightAnchor.constraint(equalToConstant: 40),
        ])
        categoryStack.addArrangedSubview(backspaceButton)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: categoryBar.topAnchor),

            categoryBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            categoryBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            categoryBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            categoryBar.heightAnchor.constraint(equalToConstant: 40),

            categoryStack.topAnchor.constraint(equalTo: categoryBar.topAnchor),
            categoryStack.leadingAnchor.constraint(equalTo: categoryBar.leadingAnchor, constant: 4),
            categoryStack.trailingAnchor.constraint(equalTo: categoryBar.trailingAnchor, constant: -4),
            categoryStack.bottomAnchor.constraint(equalTo: categoryBar.bottomAnchor),
        ])

        updateCategoryHighlight()
    }

    // MARK: - Actions

    @objc private func abcTapped() {
        onBackToKeyboard?()
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        currentCategoryIndex = sender.tag
        collectionView.reloadData()
        collectionView.setContentOffset(.zero, animated: false)
        updateCategoryHighlight()
    }

    @objc private func backspaceTapped() {
        onEmojiSelected?(KeyboardLayoutView.backKey)
    }

    // MARK: - Category Highlight

    private func updateCategoryHighlight() {
        for (index, btn) in categoryButtons.enumerated() {
            btn.tintColor = (index == currentCategoryIndex) ? .systemBlue : (isDark ? .lightGray : .gray)
        }
    }

    // MARK: - Public

    func updateAppearance(isDark: Bool) {
        self.isDark = isDark
        backgroundColor = isDark ? UIColor(white: 0.08, alpha: 1) : UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1)
        categoryBar.backgroundColor = isDark ? UIColor(white: 0.15, alpha: 1) : UIColor(white: 0.92, alpha: 1)
        abcButton.setTitleColor(isDark ? .white : .black, for: .normal)
        backspaceButton.tintColor = isDark ? .white : .black
        updateCategoryHighlight()
    }
}

// MARK: - UICollectionView DataSource & Delegate

extension EmojiKeyboardView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories[currentCategoryIndex].emojis.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath) as! EmojiCell
        cell.label.text = categories[currentCategoryIndex].emojis[indexPath.item]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let emoji = categories[currentCategoryIndex].emojis[indexPath.item]
        onEmojiSelected?(emoji)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalWidth = collectionView.bounds.width - 16 // 8 + 8 insets
        let columns: CGFloat = 8
        let spacing: CGFloat = 4 * (columns - 1)
        let cellWidth = floor((totalWidth - spacing) / columns)
        return CGSize(width: cellWidth, height: cellWidth)
    }
}

// MARK: - Custom Flow Layout (to suppress constraint warnings)

private class UIFlowLayout: UICollectionViewFlowLayout {}

// MARK: - Emoji Cell

private class EmojiCell: UICollectionViewCell {

    let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 30)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
