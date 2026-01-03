import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:go_router/go_router.dart';
import 'package:sumquiz/services/iap_service.dart';
import 'package:sumquiz/models/user_model.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  ProductDetails? _selectedProduct;
  List<ProductDetails> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final iapService = context.read<IAPService?>();
    if (iapService != null) {
      // Create display products wrapper or just use raw list
      // We expect 3 products.
      final products = await iapService.getAvailableProducts();
      // Sort them to match order: Monthly, Yearly, Lifetime
      // Monthly < Yearly < Lifetime usually by price or ID logic
      products.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));

      if (mounted) {
        setState(() {
          _products = products;
          // Default to Annual (Best Value) if available, or first
          // Usually Monthly is low price, Yearly mid, Lifetime high
          // If we have 3, index 1 is likely Yearly.
          if (_products.isNotEmpty) {
            // Try to find yearly
            _selectedProduct = _products.firstWhere(
                (p) => p.id.contains('yearly'),
                orElse: () =>
                    _products.length > 1 ? _products[1] : _products.first);
          }
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _buyProduct() async {
    if (_selectedProduct == null) return;
    final iapService = context.read<IAPService?>();
    if (iapService != null) {
      await iapService.purchaseProduct(_selectedProduct!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is already Pro
    final user = context.watch<UserModel?>();
    if (user != null && user.isPro) {
      return _buildAlreadyProView(context);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => context.pop(),
          )
        ],
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.bolt_rounded,
                                  color: Color(0xFFFFC107), size: 32),
                              const SizedBox(width: 8),
                              const Text(
                                'SumQuiz Pro',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Learn faster. Remember smarter.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Features List
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text('Features',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ))
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureRow('Unlimited content generation',
                              isUnlocked: true),
                          _buildFeatureRow('Unlimited folders & decks',
                              isUnlocked: false),
                          _buildFeatureRow('Smart Spaced Repetition',
                              isUnlocked: false),
                          _buildFeatureRow('Offline access & Sync',
                              isUnlocked: false),
                          _buildFeatureRow('Detailed progress analytics',
                              isUnlocked: false),
                          _buildFeatureRow('Daily missions & rewards',
                              isUnlocked: false),

                          const SizedBox(height: 32),

                          // Products List
                          ..._products
                              .map((product) => _buildProductCard(product)),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Section
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(color: Colors.white, boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      )
                    ]),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                _selectedProduct != null ? _buyProduct : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                  0xFF0033CC), // Deep Blue from image
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text('Upgrade to Pro',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                )),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => context.push('/referral'),
                          child: RichText(
                            text: const TextSpan(
                                style:
                                    TextStyle(fontSize: 13, color: Colors.grey),
                                children: [
                                  TextSpan(
                                      text:
                                          'Invite 3 friends and get 1 week of Pro free 🎁'),
                                ]),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureRow(String label, {required bool isUnlocked}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF555555),
              )),
          isUnlocked
              ? const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50), size: 20)
              : const Icon(Icons.lock_rounded,
                  color: Color(0xFFFFC107), size: 20)
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductDetails product) {
    final isSelected = _selectedProduct?.id == product.id;
    final isBestValue =
        product.id.contains('yearly'); // Assumption based on typical ID

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProduct = product;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    isSelected ? const Color(0xFF0033CC) : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white, // No background fill based on image
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getProductTitle(product.id),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(product.price,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    if (!product.id.contains('lifetime'))
                      Text(
                        ' /${_getPeriod(product.id)}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Checkmark and billing text
                Row(
                  children: [
                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(right: 6.0),
                        child: Icon(Icons.check, size: 16, color: Colors.black),
                      ),
                    Text(
                      _getBillingText(product.id),
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isBestValue)
            Positioned(
              right: 16,
              top: -10, // Overlap top border
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0033CC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Text('Best Value',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.diamond_outlined, color: Colors.white, size: 10),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getProductTitle(String id) {
    if (id.contains('monthly')) return 'Monthly';
    if (id.contains('yearly')) return 'Annual';
    if (id.contains('lifetime')) return 'Lifetime';
    return 'Standard';
  }

  String _getPeriod(String id) {
    if (id.contains('monthly')) return 'month';
    if (id.contains('yearly')) return 'year';
    return '';
  }

  String _getBillingText(String id) {
    if (id.contains('monthly')) return 'Billed monthly';
    if (id.contains('yearly')) return 'Billed annually';
    if (id.contains('lifetime')) return 'One-time purchase';
    return '';
  }

  Widget _buildAlreadyProView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => context.pop(),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                color: Color(0xFF0033CC), size: 80),
            const SizedBox(height: 20),
            const Text(
              'You are a Pro Member!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Enjoy unlimited access efficiently.'),
          ],
        ),
      ),
    );
  }
}
