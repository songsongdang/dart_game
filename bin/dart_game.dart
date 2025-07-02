import 'dart:io';
import 'dart:math';

// ====== 추상 클래스 ======
abstract class Unit {
  String name;
  int health;
  int attack;
  int defense;

  Unit(this.name, this.health, this.attack, this.defense);

  bool get isAlive => health > 0;

  void showStatus();
}

// ====== 캐릭터 클래스 ======
class Character extends Unit {
  bool itemUsed = false;
  int baseAttack;

  Character(super.name, super.health, super.attack, super.defense)
    : baseAttack = attack;

  void attackMonster(Monster monster) {
    int damage = max(0, attack - monster.defense);
    monster.health -= damage;
    print('$name의 공격! ${monster.name}에게 $damage 데미지');
  }

  void defend(int monsterDamage) {
    health += monsterDamage;
    print('$name가 방어! 몬스터가 입힌 데미지만큼 체력 $monsterDamage 회복');
  }

  void useItem() {
    if (!itemUsed) {
      attack *= 2;
      itemUsed = true;
      print('$name가 아이템을 사용! 이번 턴 공격력 2배');
    } else {
      print('이미 아이템을 사용했습니다.');
    }
  }

  void resetItem() {
    if (itemUsed) {
      attack = baseAttack;
      itemUsed = false;
    }
  }

  @override
  void showStatus() {
    print('[$name] 체력:$health  공격력:$attack  방어력:$defense');
  }
}

// ====== 몬스터 클래스 ======
class Monster extends Unit {
  int maxAttack;
  int turnCount = 0;

  Monster(String name, int health, this.maxAttack) : super(name, health, 0, 0);

  void setRandomAttack(int minDefense) {
    // 공격력은 캐릭터 방어력 이상~maxAttack 사이의 랜덤값
    attack = max(
      minDefense,
      minDefense + Random().nextInt(maxAttack - minDefense + 1),
    );
  }

  void attackCharacter(Character character) {
    int damage = max(0, attack - character.defense);
    character.health -= damage;
    print('$name의 공격! ${character.name}에게 $damage 데미지');
  }

  void increaseDefense() {
    defense += 2;
    print('$name의 방어력이 증가했습니다! 현재 방어력: $defense');
  }

  @override
  void showStatus() {
    print('[$name] 체력:$health  공격력:$attack  방어력:$defense');
  }
}

// ====== 게임 클래스 ======
class Game {
  late Character character;
  late List<Monster> monsters;
  int monstersDefeated = 0;

  void startGame() {
    print('==== 전투 RPG 게임을 시작합니다 ====');
    loadCharacter();
    loadMonsters();
    bonusHealth();

    while (character.isAlive && monsters.isNotEmpty) {
      // 무작위 이벤트 발생
      triggerRandomEvent();

      Monster monster = getRandomMonster();
      print('\n=== 새로운 몬스터 등장! ===');
      monster.showStatus();

      // ignore: unused_local_variable
      int turn = 0;
      monster.turnCount = 0;

      while (character.isAlive && monster.isAlive) {
        turn++;
        monster.turnCount++;

        print('\n--- 현재 상태 ---');
        character.showStatus();
        monster.showStatus();

        // 캐릭터 행동 선택
        int action = getAction();
        character.resetItem();

        if (action == 1) {
          character.attackMonster(monster);
        } else if (action == 2) {
          print('${character.name}가 방어를 선택!');
        } else if (action == 3) {
          character.useItem();
          character.attackMonster(monster);
        }

        // 몬스터 공격력 랜덤 설정
        monster.setRandomAttack(character.defense);

        // 몬스터 공격
        if (monster.isAlive) {
          if (action == 2) {
            // 방어 시 데미지만큼 체력 회복
            int damage = max(0, monster.attack - character.defense);
            character.defend(damage);
          } else {
            monster.attackCharacter(character);
          }
        }

        // 3턴마다 몬스터 방어력 증가
        if (monster.turnCount % 3 == 0) {
          monster.increaseDefense();
        }

        // 전투 종료 체크
        if (!character.isAlive) {
          print('\n${character.name}가 쓰러졌습니다. 게임 오버!');
          saveResult('패배');
          askSaveAndExit();
          return;
        }
        if (!monster.isAlive) {
          print('\n${monster.name}를 물리쳤습니다!');
          monstersDefeated++;
          monsters.remove(monster);

          if (monsters.isEmpty) {
            print('\n축하합니다! 모든 몬스터를 물리쳤습니다!');
            saveResult('승리');
            askSaveAndExit();
            return;
          } else {
            if (!askNextBattle()) {
              print('게임을 종료합니다.');
              saveResult('중도 종료');
              askSaveAndExit();
              return;
            }
            break;
          }
        }
      }
    }
  }

  void triggerRandomEvent() {
    print('\n[이벤트 발생]');
    final rand = Random().nextDouble();
    if (rand < 0.25) {
      // 회복의 샘
      int heal = 10 + Random().nextInt(11); // 10~20 회복
      character.health += heal;
      print('회복의 샘을 발견! 체력이 $heal 회복되었습니다.');
    } else if (rand < 0.45) {
      // 함정
      int damage = 5 + Random().nextInt(6); // 5~10 데미지
      character.health -= damage;
      print('함정에 빠졌습니다! 체력이 $damage 감소했습니다.');
      if (character.health <= 0) {
        character.health = 0;
        print('${character.name}가 쓰러졌습니다...');
      }
    } else if (rand < 0.65) {
      // 신비한 상자
      int rewardType = Random().nextInt(2);
      if (rewardType == 0) {
        character.attack += 2;
        print('신비한 상자를 열어 공격력이 2 상승했습니다!');
      } else {
        character.defense += 2;
        print('신비한 상자를 열어 방어력이 2 상승했습니다!');
      }
    } else if (rand < 0.80) {
      // 수상한 상인
      print('수상한 상인을 만났습니다. 아이템(공격력 2배, 1회용)을 5 체력과 교환하시겠습니까? (y/n)');
      String? input = stdin.readLineSync();
      if (input != null && input.toLowerCase() == 'y') {
        if (character.health > 5) {
          character.health -= 5;
          character.itemUsed = false; // 아이템 사용 가능 상태로
          print('아이템을 획득했습니다! (이번 전투 중 한 번 사용 가능)');
        } else {
          print('체력이 부족하여 거래할 수 없습니다.');
        }
      } else {
        print('상인을 무시하고 지나갑니다.');
      }
    } else {
      // 휴식
      int heal = 5 + Random().nextInt(6);
      character.health += heal;
      print('잠시 휴식을 취해 체력이 $heal 회복되었습니다.');
    }
  }

  void loadCharacter() {
    try {
      final file = File('characters.txt');
      final contents = file.readAsStringSync().trim();
      final stats = contents.split(',');
      if (stats.length != 3) throw FormatException('Invalid character data');
      int health = int.parse(stats[0]);
      int attack = int.parse(stats[1]);
      int defense = int.parse(stats[2]);
      String name = getCharacterName();
      character = Character(name, health, attack, defense);
    } catch (e) {
      print('캐릭터 데이터를 불러오는 데 실패했습니다: $e');
      exit(1);
    }
  }

  void loadMonsters() {
    try {
      final file = File('monsters.txt');
      final lines = file.readAsLinesSync();
      monsters = [];
      for (final line in lines) {
        final parts = line.trim().split(',');
        if (parts.length != 3) continue;
        monsters.add(
          Monster(parts[0], int.parse(parts[1]), int.parse(parts[2])),
        );
      }
      if (monsters.isEmpty) throw FormatException('No monsters loaded');
    } catch (e) {
      print('몬스터 데이터를 불러오는 데 실패했습니다: $e');
      exit(1);
    }
  }

  void bonusHealth() {
    if (Random().nextDouble() < 0.3) {
      character.health += 10;
      print('보너스 체력을 얻었습니다! 현재 체력: ${character.health}');
    }
  }

  Monster getRandomMonster() {
    return monsters[Random().nextInt(monsters.length)];
  }

  int getAction() {
    while (true) {
      stdout.write('행동 선택: 공격(1), 방어(2), 아이템(3) > ');
      String? input = stdin.readLineSync();
      if (input == null) continue;
      if (input == '1' || input == '2' || input == '3') {
        return int.parse(input);
      }
      print('잘못된 입력입니다. 1, 2, 3 중 하나를 입력하세요.');
    }
  }

  String getCharacterName() {
    while (true) {
      stdout.write('캐릭터 이름을 입력하세요(한글/영문만): ');
      String? name = stdin.readLineSync();
      if (name != null &&
          name.isNotEmpty &&
          RegExp(r'^[a-zA-Z가-힣]+$').hasMatch(name)) {
        return name;
      }
      print('이름은 한글/영문만 가능합니다.');
    }
  }

  bool askNextBattle() {
    while (true) {
      stdout.write('다음 몬스터와 대결하시겠습니까? (y/n): ');
      String? input = stdin.readLineSync();
      if (input == null) continue;
      if (input.toLowerCase() == 'y') return true;
      if (input.toLowerCase() == 'n') return false;
      print('y 또는 n만 입력하세요.');
    }
  }

  void saveResult(String result) {
    while (true) {
      stdout.write('결과를 저장하시겠습니까? (y/n): ');
      String? input = stdin.readLineSync();
      if (input == null) continue;
      if (input.toLowerCase() == 'y') {
        try {
          final file = File('result.txt');
          file.writeAsStringSync(
            '${character.name},${character.health},$result\n',
            mode: FileMode.append,
          );
          print('결과가 저장되었습니다.');
        } catch (e) {
          print('결과 저장에 실패했습니다: $e');
        }
        break;
      } else if (input.toLowerCase() == 'n') {
        print('결과를 저장하지 않습니다.');
        break;
      } else {
        print('y 또는 n만 입력하세요.');
      }
    }
  }

  void askSaveAndExit() {
    print('게임을 종료합니다.');
    exit(0);
  }
}

void main() {
  Game game = Game();
  game.startGame();
}
