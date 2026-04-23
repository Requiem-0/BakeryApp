import '../../../../features/catalogue/data/models/product.dart';
import '../../../../features/catalogue/data/models/category.dart';
import '../../../../features/orders/data/models/order.dart';
import '../../../../features/address/data/models/address.dart';

/// All static data for the app.
abstract final class CatalogueLocalDatasource {
  static const List<Category> categories = [
    Category(id: 'breads', label: 'Breads', icon: '🍞', count: 12),
    Category(id: 'pastries', label: 'Pastries', icon: '🥐', count: 18),
    Category(id: 'cakes', label: 'Cakes', icon: '🎂', count: 9),
    Category(id: 'cookies', label: 'Cookies', icon: '🍪', count: 15),
  ];

  static const List<Product> products = [
    Product(
      id: 1,
      name: 'Sourdough Boule',
      category: 'breads',
      price: 8.50,
      rating: 4.9,
      reviews: 124,
      image: '🍞',
      badge: 'Bestseller',
      description:
          'Our signature 48-hour fermented sourdough with a crackling crust and tender, airy crumb. Made with heritage wheat flour.',
      tags: ['Organic', 'Vegan'],
      time: '48hr ferment',
      variants: [
        VariantGroup(title: 'Size', options: ['Small', 'Medium', 'Large']),
      ],
    ),
    Product(
      id: 2,
      name: 'Pain au Chocolat',
      category: 'pastries',
      price: 5.25,
      rating: 4.8,
      reviews: 89,
      image: '🥐',
      badge: 'New',
      description:
          'Buttery, flaky layers wrapped around two bars of premium Belgian dark chocolate. Baked fresh every morning.',
      tags: ['Contains Dairy'],
      time: 'Fresh daily',
    ),
    Product(
      id: 3,
      name: 'Raspberry Tart',
      category: 'pastries',
      price: 7.00,
      rating: 4.7,
      reviews: 67,
      image: '🫐',
      badge: null,
      description:
          'Crisp almond pastry shell filled with vanilla custard and topped with fresh raspberries and a light glaze.',
      tags: ['Contains Nuts'],
      time: 'Made to order',
    ),
    Product(
      id: 4,
      name: 'Chocolate Layer Cake',
      category: 'cakes',
      price: 42.00,
      rating: 5.0,
      reviews: 203,
      image: '🎂',
      badge: 'Popular',
      description:
          'Three layers of rich dark chocolate sponge, filled with ganache and finished with Belgian chocolate shavings.',
      tags: ['Gluten-Free Option'],
      time: '24hr notice',
      variants: [
        VariantGroup(title: 'Size', options: ['6 inch', '8 inch', '10 inch']),
        VariantGroup(title: 'Filling', options: ['Ganache', 'Mousse', 'Cream']),
      ],
    ),
    Product(
      id: 5,
      name: 'Ciabatta Loaf',
      category: 'breads',
      price: 6.75,
      rating: 4.6,
      reviews: 55,
      image: '🥖',
      badge: null,
      description:
          'Italian-style bread with an incredibly open crumb and crispy, olive oil-brushed crust. Perfect for sandwiches.',
      tags: ['Vegan'],
      time: 'Baked daily',
    ),
    Product(
      id: 6,
      name: 'Almond Croissant',
      category: 'pastries',
      price: 6.00,
      rating: 4.9,
      reviews: 156,
      image: '🥐',
      badge: 'Bestseller',
      description:
          'Day-old croissant filled with almond frangipane, topped with sliced almonds and powdered sugar.',
      tags: ['Contains Nuts', 'Contains Dairy'],
      time: 'Limited daily',
    ),
    Product(
      id: 7,
      name: 'Butter Croissant',
      category: 'pastries',
      price: 4.50,
      rating: 4.8,
      reviews: 180,
      image: '🥐',
      badge: null,
      description:
          'Classic French butter croissant — laminated dough with 27 layers for the perfect flaky, golden-brown result.',
      tags: ['Contains Dairy'],
      time: 'Fresh daily',
    ),
    Product(
      id: 8,
      name: 'Lemon Drizzle Cake',
      category: 'cakes',
      price: 28.00,
      rating: 4.7,
      reviews: 92,
      image: '🍋',
      badge: 'New',
      description:
          'Light and lemony pound cake soaked in citrus drizzle, perfect for sharing.',
      tags: ['Vegan'],
      time: '24hr notice',
    ),
    Product(
      id: 9,
      name: 'Chocolate Chip Cookie',
      category: 'cookies',
      price: 2.50,
      rating: 4.9,
      reviews: 310,
      image: '🍪',
      badge: 'Bestseller',
      description:
          'Thick and chewy chocolate chip cookies made with Belgian chocolate chunks and a touch of sea salt.',
      tags: ['Contains Dairy'],
      time: 'Baked daily',
      variants: [
        VariantGroup(title: 'Type', options: ['Dark', 'Milk', 'White']),
        VariantGroup(title: 'Size', options: ['Regular', 'Large']),
      ],
    ),
    Product(
      id: 10,
      name: 'Cinnamon Roll',
      category: 'pastries',
      price: 5.50,
      rating: 4.8,
      reviews: 140,
      image: '🌀',
      badge: null,
      description:
          'Soft, pillowy rolls with cinnamon-sugar swirl and a cream cheese glaze. Best enjoyed warm.',
      tags: ['Contains Dairy'],
      time: 'Fresh daily',
    ),
  ];

  static const List<Order> recentOrders = [
    Order(
      id: '#2847',
      date: 'Today, 10:32 AM',
      items: [
        OrderItem(name: 'Sourdough Boule', image: '🍞', qty: 1),
        OrderItem(name: 'Almond Croissant', image: '🥐', qty: 2),
      ],
      total: 20.50,
      status: 'Picked Up',
    ),
    Order(
      id: '#2831',
      date: 'Feb 21, 9:15 AM',
      items: [
        OrderItem(name: 'Pain au Chocolat', image: '🥐', qty: 3),
        OrderItem(name: 'Ciabatta Loaf', image: '🥖', qty: 1),
      ],
      total: 22.50,
      status: 'Picked Up',
    ),
    Order(
      id: '#2809',
      date: 'Feb 18, 11:00 AM',
      items: [
        OrderItem(name: 'Chocolate Layer Cake', image: '🎂', qty: 1),
      ],
      total: 44.50,
      status: 'Picked Up',
    ),
    Order(
      id: '#2794',
      date: 'Feb 15, 8:45 AM',
      items: [
        OrderItem(name: 'Raspberry Tart', image: '🫐', qty: 1),
        OrderItem(name: 'Sourdough Boule', image: '🍞', qty: 2),
      ],
      total: 24.00,
      status: 'Picked Up',
    ),
  ];

  static const List<Address> savedAddresses = [
    Address(
      id: 1,
      label: 'Breaking Bread Bakery',
      address: '17th street, Lakeside, Pokhara, Nepal',
      icon: '🏠',
      type: 'Pickup',
    ),
    Address(
      id: 2,
      label: 'Brand Builder Office',
      address: "Niva galli, Chipledhunga, Pokhara, Nepal",
      icon: '💼',
      type: 'Pick up',
    ),
    Address(
      id: 3,
      label: 'Home',
      address: 'your home address here',
      icon: '🏡',
      type: 'Delivery',
    ),
  ];

  static const List<String> dietaryFilterOptions = [
    'Organic',
    'Vegan',
    'Gluten-Free Option',
    'Contains Nuts',
    'Contains Dairy',
  ];

  static const List<String> dietaryPreferenceOptions = [
    'None',
    'Vegan',
    'Gluten-Free',
    'Nut-Free',
    'Dairy-Free',
    'Low Sugar',
  ];
}
